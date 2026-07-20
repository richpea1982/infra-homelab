# K3s Node Auto-DR — Semaphore & OPNsense Setup

This covers everything the `alert_router` Ansible role and the
`kube-prometheus-stack` ArgoCD Application can't set up for you — Semaphore's
Task Templates are configured through its UI/DB, not GitOps, and the
OPNsense firewall rule is a manual network change.

---

## 1. OPNsense — new firewall rule (do this first, nothing else works without it)

Alertmanager (running in K3s, VLAN20) needs to reach the alert-router on
pve1 (VLAN10). Your current policy only opens VLAN20→VLAN10 for MinIO on
9000/9001 — everything else is dropped by default.

Add:
- **Source:** VLAN20 subnet (10.0.20.0/24) — or scope tighter to just
  10.0.20.21–.23 if you want to match the existing MinIO rule's precision
- **Destination:** 10.0.10.17
- **Port:** TCP/8080
- **Action:** Allow

## 2. Semaphore — dedicated automation user + API token

Don't reuse your personal `rich` login's token for this — a compromised or
buggy alert-router shouldn't have your full admin session. Create a
separate low-privilege Semaphore user scoped to just this project if your
Semaphore version supports project-level roles, and generate its API token
via:

```
curl -s -c /tmp/semaphore-cookie -X POST \
  -H 'Content-Type: application/json' \
  -d '{"auth": "automation-user", "password": "..."}' \
  http://10.0.10.17:3000/api/auth/login

curl -s -b /tmp/semaphore-cookie -X POST \
  -H 'Content-Type: application/json' \
  http://10.0.10.17:3000/api/user/tokens
```

Store the resulting token as `vault_semaphore_alert_router_token` in
`ansible/group_vars/all/vault.yml`.

## 3. Semaphore — two Task Templates

**Template A: `k3s-node-rebuild` (Shell/Bash task type)**

```bash
cd /path/to/infra-homelab/terraform
terraform init
terraform apply -auto-approve \
  -replace="module.k3s_node[\"${node_name}\"].proxmox_virtual_environment_vm.this"
```

Add a Survey Variable `node_name` (type: Enum — `pve2`, `pve3`, `pve4`).
The alert-router supplies this via the `environment` field on the API call,
so no manual input is needed at run time — the survey variable just gives
Semaphore a name to bind the incoming value to.

**Template B: `k3s-ansible-rejoin` (Ansible task type)**

Points at `ansible/deploy_k3s.yml` (via the symlink, not
`playbooks/deploy_k3s.yml` directly — same rule as manual runs). No survey
variables needed: the existing VIP-reachability-probe join logic in
`join.yml`/`bootstrap.yml` is already idempotent and rejoin-safe by design,
which is exactly why this works as the second stage here with zero changes.

Note both templates' numeric IDs (visible in the Semaphore UI URL when
editing them) — these go into `semaphore_project_id`,
`semaphore_terraform_replace_template_id`, and
`semaphore_ansible_rejoin_template_id` in group_vars.

## 4. Known limitation to test deliberately, not assume away

`terraform apply -replace` destroys and recreates the VM. That's correct
for a genuinely dead node. But if the "down" node was actually still
alive — network partition rather than a crashed VM — replacing it means a
new etcd member joins while the old member's identity may not have been
cleanly removed from the cluster's member list first. Whether this
resolves itself (etcd's own health checks evicting the stale member) or
leaves cruft behind needs an actual test, not an assumption.

## 5. Recommended test sequence, in order

1. Manually `systemctl stop k3s` on **pve4** (lowest-resource node, least
   consequential if something goes sideways) — don't touch the VM in
   Proxmox yet, just the service. Confirm the `K3sNodeDown` alert fires
   after 5 minutes and the alert-router logs pick it up.
2. Check `journalctl -u alert-router -f` on pve1 during the test — confirm
   it refuses to act if you (deliberately, for this test) also stop k3s on
   a second node briefly, to prove the multi-node-down guardrail actually
   works before you ever rely on the single-node path.
3. Once single-node detection is confirmed, let a real single-node test
   run end-to-end: stop the VM itself in Proxmox (not just the service) so
   Terraform's `-replace` has something real to do, and watch both
   Semaphore tasks complete and the node rejoin via `kubectl get nodes`.
4. Only after a clean end-to-end pass should you consider this trusted for
   an actual unattended failure.
