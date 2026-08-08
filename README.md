# infra-homelab

Personal homelab infrastructure managed as code.

This repository is the **source of truth** for the physical and virtual infrastructure of my homelab.  
It provisions and configures Proxmox hosts, K3s nodes, media LXCs, WordPress VMs, the NAS, and the automation control node using **Terraform** and **Ansible**.

Related repositories:
- [`k3s`](https://github.com/richpea1982/k3s) — GitOps manifests (ArgoCD) for workloads running on the K3s cluster
- Portfolio site — [richpea1982.github.io](https://richpea1982.github.io)

> **Status (August 2026)**  
> The Proxmox cluster, networking, NAS, WordPress VMs and automation tooling are in daily use.  
> The 3-node K3s cluster is bootstrapped and under active validation (HA control-plane, self-healing, GitOps sync).  
> Stateless services are being migrated progressively.  
> This README always reflects the **current intended architecture**. Older notes in `docs/infra-notes/` may lag behind and should not be treated as authoritative.

---

## High-level architecture

Five physical machines:

| Role                        | Host          | Purpose                                                                 |
|-----------------------------|---------------|-------------------------------------------------------------------------|
| Management / control plane  | **pve1**      | OPNsense (routing & firewall), Proxmox Backup Server, automation node (Semaphore + Ansible control) — deliberately kept **outside** the compute cluster |
| Compute + Ceph              | **pve2, pve3, pve4** | Proxmox VE cluster with Ceph storage. Hosts K3s VMs, public WordPress VMs, and media LXCs |
| Storage                     | **NAS** (bare metal) | Debian + ZFS RAID-Z2 (6 × 1 TB). NFS shares + MinIO (S3-compatible)     |

### Network segmentation (VLANs)

| VLAN | Subnet          | Purpose                              |
|------|-----------------|--------------------------------------|
| 10   | 10.0.10.0/24    | Management (Proxmox, PBS, automation, NAS) |
| 20   | 10.0.20.0/24    | Internal services / K3s              |
| 30   | 10.0.30.0/24    | Media (Jellyfin, etc.)               |
| 40   | 10.0.40.0/24    | Public-facing web VMs (DMZ)          |
| 50   | 10.0.50.0/24    | Untrusted / lab                      |

Inbound public traffic uses **Cloudflare Tunnels** only (no ports opened on the firewall).  
Internal admin access is via WireGuard / Tailscale overlay.

### Key design choices

- **K3s system disks on local-lvm** (not Ceph) — etcd is latency-sensitive; network storage would risk quorum issues.
- **WordPress / stateful non-K3s workloads on Ceph** — allows live migration / HA restart on another Proxmox node.
- **Media LXCs on local storage + NFS from NAS** — GPU passthrough + large media libraries stay off Ceph.
- **Automation & backup control plane isolated on pve1** — avoids chicken-and-egg problems if the compute cluster fails.
- **GitOps after bootstrap** — Ansible brings up the K3s cluster + ArgoCD; everything afterwards is declared in the `k3s` repository and reconciled by ArgoCD.

---

## Repository layout
infra-homelab/
├── terraform/                  # Proxmox VMs & LXCs
│   ├── modules/
│   │   ├── vm/
│   │   └── lxc/
│   ├── *.auto.tfvars           # Node definitions (k3s, media, WordPress)
│   └── ...
├── ansible/
│   ├── playbooks/              # Entry-point playbooks
│   ├── roles/                  # k3s_cluster, nas_setup, jellyfin, smartctl_exporter, automation_control, alert_router...
│   ├── group_vars/
│   └── hosts/
├── docs/infra-notes/           # Working notes (may be outdated — see this README first)
└── docker-images/portfolio/    # Test image for the portfolio site inside K3s


---

## Current inventory (as coded)

### K3s nodes (VLAN 20, local-lvm)

| Name       | Proxmox host | VMID | IP            | Cores | RAM   |
|------------|--------------|------|---------------|-------|-------|
| k3s-pve2   | pve2         | 2021 | 10.0.20.21/24 | 3     | 7 GB  |
| k3s-pve3   | pve3         | 2022 | 10.0.20.22/24 | 3     | 7 GB  |
| k3s-pve4   | pve4         | 2023 | 10.0.20.23/24 | 3     | 6 GB  |

API endpoint (kube-vip): `10.0.20.20:6443`

### Public WordPress VMs (VLAN 40, Ceph)

| Name           | Proxmox host | VMID | IP            | Cores | RAM  |
|----------------|--------------|------|---------------|-------|------|
| hantaweb       | pve3         | 4011 | 10.0.40.11/24 | 3     | 4 GB |
| petitsanglais  | pve4         | 4012 | 10.0.40.12/24 | 1     | 1 GB |
| hanta-assos    | pve3         | 4013 | 10.0.40.13/24 | 1     | 1 GB |

### Media LXC (VLAN 30)

| Name     | Proxmox host | VMID | IP            | Notes                          |
|----------|--------------|------|---------------|--------------------------------|
| jellyfin | pve2         | 3010 | 10.0.30.10/24 | Privileged (GPU passthrough), media library on NFS from NAS |

(Additional media / photo services are being validated.)

### Management (pve1 + NAS)

- OPNsense, PBS, automation control node (Semaphore) on pve1 (VLAN 10)
- NAS: ZFS RAID-Z2 + MinIO + NFS exports (seafile, jellyfin, photoprism, backups, etc.)

---

## How the pieces fit together

1. **Terraform** creates the VMs and LXCs on Proxmox (and downloads the LXC template).
2. **Ansible** configures the OS, bootstraps the K3s cluster (HA etcd, kube-vip, Calico, ArgoCD), sets up the NAS (ZFS, NFS, MinIO), and deploys supporting roles (smartctl exporter, alert router, etc.).
3. **ArgoCD** (from the `k3s` repo) takes over application deployment and continuous reconciliation (Traefik, CrowdSec, monitoring stack, Cloudflare tunnel, portfolio, Vaultwarden, Velero, etc.).

Secrets are stored in **Ansible Vault** (`ansible/group_vars/all/vault.yml`).  
Terraform state is stored on the NAS MinIO bucket.

---

## Quick start (high level)

Detailed steps live in the role READMEs (especially `ansible/roles/k3s_cluster/K3S-BOOTSTRAP-README.md`).

Typical sequence:

```bash
# 1. Provision infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 2. Configure control node & NAS (from the automation host)
cd ../ansible
ansible-playbook -i hosts/hosts.ini playbooks/deploy_control_node.yml
ansible-playbook -i hosts/hosts.ini nas_setup.yml

# 3. Bootstrap K3s
ansible-playbook -i hosts/hosts.ini deploy_k3s.yml
# (follow the post-bootstrap steps in the K3s role README: deploy key, verify ArgoCD, etc.)

```

Design principles I follow

Prefer declarative IaC over manual changes.
Isolate the management plane from the compute plane.
Keep latency-sensitive components (etcd) on local storage.
Expose nothing publicly except through Cloudflare Tunnels + Traefik + CrowdSec.
Document decisions and failures (see docs/ and the portfolio “lessons learned” page).

This is a constrained home lab built on older hardware. The goal is to practice production-style patterns (IaC, GitOps, HA, observability, least-privilege networking) under real resource limits, not to claim enterprise scale.

Licence / contact
Personal project — no licence applied.
Questions or feedback: see the portfolio site or open an issue.
