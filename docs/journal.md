# journal

Score-keeping for decisions made in sessions: what and WHY (not a step log).
Format:

## YYYY-MM-DD — topic
- decision, reason, ticket ref

## 2026-09-17 — opencode project scaffolding
- Added AGENTS.md + opencode.json + journal to both repos so the working
  agreement survives across stateless sessions. refs #22

## 2026-09-17 — CI pipeline (GitHub Actions)
- Added .github/workflows/ci.yml: terraform fmt -check + init -backend=false
  + validate, yamllint, ansible-lint, ansible-playbook --syntax-check.
  refs #21
- CI is a real gate now: first runs surfaced genuine issues (fmt on 6 files,
  comments, stale key read) — not theoretical nits.

## 2026-09-17 — terraform fmt + comment cleanup
- Ran terraform fmt on the root module; whitespace/alignment only, no logic.
  refs #25
- Removed stale dev-note/shrapnel comments ("ADD THIS BLOCK", "Append this
  block" banners, commented-out agent line, mislabeled "Second Ceph VM").
  Decision: comments earn keeping by explaining WHY; rest, state and
  duplicates have no place in committed IaC.

## 2026-09-17 — SSH key source is on the automation node, not a guard
- Root cause of CI failure: coalesce() is eager — file() ran even when the
  key was unused, so init/validate died on runners without the file.
- Fix: fileexists()-gated lazy read, byte-identical value in production,
  plus lifecycle preconditions on both provisioning modules so a null key
  aborts at plan/apply instead of creating a keyless host. refs #27
- Decision: never let "missing key" become "empty key in cloud-init" — no
  password auth exists on these hosts, so that is an unreachable VM.
- Unresolved: drift where tfstate on petitsanglais (4012) holds 2 keys but
  the file now has 1 (rpearsall1982 being removed). Determined pre-existing,
  unrelated to the fix. Gate: verify ~/.ssh/id_terraform.pub contents before
  applying the drift-repair.

## 2026-09-17 — SSH key injection lives in Ansible, not Terraform
- Decision: additional keys (home/school PCs) are injected via Ansible at
  configure time, reusing the terraform bootstrap key. refs #29
- Rationale: Terraform cloud-init stays minimal (single bootstrap key); keys
  follow configuration, not state.
- Known gap accepted: WordPress VMs (hantaweb/petitsanglais/hantaassos) are
  NOT in the Ansible inventory and have no roles — stand-by pending the
  LXC-to-VM migration. They are excluded from key injection until then.
  refs #30

## 2026-09-17 — provider deprecation debt accepted
- proxmox_virtual_environment_download_file is deprecated (removed in bpg
  v1.0); rename to proxmox_download_file. Non-blocking, scheduled via #28.
- .terraform.lock.hcl left untracked pending a decision on committing it.