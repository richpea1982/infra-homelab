"""
Alert Router — receives Alertmanager webhooks and drives automated K3s
node disaster recovery via Semaphore (Terraform replace + Ansible rejoin).

Runs on pve1, co-located with Semaphore/Terraform/Ansible — deliberately
kept OUTSIDE the K3s cluster it remediates, for the same reason OPNsense,
PBS, and Semaphore itself stay off the cluster: if this lived in K3s, a
cluster-wide outage could take down the very thing meant to fix it.

Safety model:
  - Only ONE remediation runs at a time (state file acts as the lock).
  - If more than one node is reported down at the same time, auto-rebuild
    is REFUSED. Two-plus control-plane nodes down simultaneously usually
    means either etcd quorum is already gone (nothing Terraform does fixes
    that) or there's a shared-cause failure (switch/VLAN/power) — not a
    single dead VM. Blindly replacing multiple etcd members at once risks
    turning a recoverable outage into permanent data loss. This case is
    logged as critical and left for manual intervention, full stop.
  - A per-node cooldown prevents rebuild loops if the Ansible rejoin step
    fails repeatedly.

Known limitation to validate during testing (see semaphore-dr-setup.md):
`terraform apply -replace` destroys and recreates the VM, but if the node
was actually still alive (network partition, not a dead VM) rather than
truly gone, the old etcd member entry may not be cleanly removed from the
cluster's member list before the replacement joins. Test this scenario
deliberately — don't assume it's handled.
"""

import asyncio
import json
import logging
import os
import time
from contextlib import contextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("alert-router")

app = FastAPI(title="Homelab Alert Router")

STATE_FILE = Path(os.environ.get("ALERT_ROUTER_STATE", "/var/lib/alert-router/state.json"))
STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

SEMAPHORE_URL = os.environ["SEMAPHORE_URL"]  # e.g. http://127.0.0.1:3000 (same host)
SEMAPHORE_TOKEN = os.environ["SEMAPHORE_TOKEN"]
SEMAPHORE_PROJECT_ID = os.environ["SEMAPHORE_PROJECT_ID"]
TERRAFORM_TEMPLATE_ID = os.environ["SEMAPHORE_TERRAFORM_REPLACE_TEMPLATE_ID"]
ANSIBLE_TEMPLATE_ID = os.environ["SEMAPHORE_ANSIBLE_REJOIN_TEMPLATE_ID"]

VALID_NODES = {"pve2", "pve3", "pve4"}
COOLDOWN_SECONDS = int(os.environ.get("ALERT_ROUTER_COOLDOWN", 1800))  # 30 min
POLL_INTERVAL = 10
POLL_TIMEOUT = 900  # 15 min ceiling per Semaphore task


def _load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"nodes_down": {}, "lock": None, "cooldowns": {}}


def _save_state(state: dict) -> None:
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2))
    tmp.replace(STATE_FILE)


@contextmanager
def _locked_state():
    # Single process, single systemd unit — no concurrent writers, so a
    # plain read-modify-write is enough. If this ever runs with more than
    # one worker, swap this for a real file lock (fcntl.flock).
    state = _load_state()
    yield state
    _save_state(state)


class AlertmanagerWebhook(BaseModel):
    status: str
    alerts: list[dict]


@app.post("/webhook/alertmanager")
async def receive_webhook(payload: AlertmanagerWebhook):
    relevant = [a for a in payload.alerts if a.get("labels", {}).get("alertname") == "K3sNodeDown"]
    if not relevant:
        return {"ignored": True}

    with _locked_state() as state:
        for alert in relevant:
            node = alert.get("labels", {}).get("node")
            if node not in VALID_NODES:
                log.warning("Alert for unrecognised node label %r — ignoring", node)
                continue
            if alert.get("status") == "firing":
                state["nodes_down"][node] = time.time()
                log.info("Node %s marked DOWN", node)
            else:
                state["nodes_down"].pop(node, None)
                log.info("Node %s marked RECOVERED", node)

        down_nodes = list(state["nodes_down"].keys())

    if len(down_nodes) > 1:
        log.critical(
            "MULTIPLE nodes down simultaneously (%s) — refusing auto-rebuild. "
            "Likely shared-cause failure or etcd quorum already lost. "
            "Manual intervention required.",
            down_nodes,
        )
        return {"action": "refused_multi_node_down", "nodes": down_nodes}

    if len(down_nodes) == 1:
        node = down_nodes[0]
        asyncio.create_task(_maybe_remediate(node))
        return {"action": "remediation_considered", "node": node}

    return {"action": "none"}


async def _maybe_remediate(node: str):
    with _locked_state() as state:
        if state.get("lock"):
            log.info("Remediation already in progress (%s) — skipping", state["lock"])
            return
        cooldown_until = state["cooldowns"].get(node, 0)
        if time.time() < cooldown_until:
            log.info("Node %s is in cooldown until %s — skipping", node, cooldown_until)
            return
        # Still down right now? A near-simultaneous "resolved" webhook could
        # have landed while we were waiting to acquire this.
        if node not in state["nodes_down"]:
            log.info("Node %s recovered before remediation started", node)
            return
        state["lock"] = node

    log.warning("Starting auto-remediation for node %s", node)
    try:
        await _run_semaphore_template(TERRAFORM_TEMPLATE_ID, {"node_name": node}, label="terraform-replace")
        await _run_semaphore_template(ANSIBLE_TEMPLATE_ID, {}, label="ansible-rejoin")
        log.warning("Remediation for %s completed successfully", node)
    except Exception:
        log.exception("Remediation for %s FAILED — needs manual review", node)
    finally:
        with _locked_state() as state:
            state["lock"] = None
            state["cooldowns"][node] = time.time() + COOLDOWN_SECONDS
            state["nodes_down"].pop(node, None)


async def _run_semaphore_template(template_id: str, env: dict, label: str) -> None:
    """
    Uses Semaphore's documented POST /api/project/{id}/tasks endpoint
    (confirmed: {"template_id": N, "environment": "<json string>"}).
    Polling field names (GET .../tasks/{id} -> "status") follow the
    conventional REST pattern but haven't been verified against your
    specific Semaphore version — check /api-docs on your instance before
    trusting this in production, and adjust if the field name differs.
    """
    headers = {
        "Authorization": f"Bearer {SEMAPHORE_TOKEN}",
        "Content-Type": "application/json",
    }
    body = {"template_id": int(template_id), "environment": json.dumps(env)}
    url = f"{SEMAPHORE_URL}/api/project/{SEMAPHORE_PROJECT_ID}/tasks"

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=headers, json=body)
        resp.raise_for_status()
        task_id = resp.json()["id"]
        log.info("[%s] Semaphore task %s started (template %s)", label, task_id, template_id)

        deadline = time.time() + POLL_TIMEOUT
        status_url = f"{url}/{task_id}"
        while time.time() < deadline:
            await asyncio.sleep(POLL_INTERVAL)
            poll = await client.get(status_url, headers=headers)
            poll.raise_for_status()
            status = poll.json().get("status")
            log.info("[%s] Semaphore task %s status: %s", label, task_id, status)
            if status == "success":
                return
            if status in ("error", "fail", "failed"):
                raise RuntimeError(f"Semaphore task {task_id} ({label}) failed")
        raise TimeoutError(f"Semaphore task {task_id} ({label}) did not finish within {POLL_TIMEOUT}s")


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
