# Homelab Virtual Infrastructure Architecture

This document defines the finalised VM/LXC placement plan for a 3‑node Proxmox cluster with mixed Intel/AMD CPUs, Ceph storage, Kubernetes, public web VMs, and internal LXCs.

It is the reference blueprint for the Terraform rewrite.

---

## Cluster Overview

| Node | CPU | RAM | Notes |
|------|------|------|-------|
| **pve1** | Intel i5‑6500 (4c) | 16GB | Strongest single‑core; ideal for web + k8s worker |
| **pve2** | AMD PRO A10‑9700E (4c) | 16GB | Weakest CPU; ideal for infra, LXCs, k8s worker |
| **pve3** | Intel i7‑4500U (4c) | 16GB | Low‑TDP mobile CPU; good for light web + Jellyfin |

**Shared storage:** 3× Ceph OSD (1TB each)  
**Reserved per node:** ~4GB for Proxmox + Ceph → **~12GB usable per node**

---

# pve1 — Primary Web + Kubernetes Worker

### Role
- Primary host for the WooCommerce store  
- Strong single‑core performance  
- Runs one k8s control plane + one worker  
- Intel CPU → safe migration with pve3

---

### Virtual Machines

| Service | Type | vCPU | RAM | VLAN | HA Group | Notes |
|--------|------|------|------|-------|----------|-------|
| **k8s‑cp‑1** | VM | 1 | 2GB | Internal | k8s‑cp | Control plane node #1 |
| **k8s‑worker‑1** | VM | 2 | 4GB | Internal | k8s‑workers | Main production worker |
| **web‑store** | VM | 3 | 4GB | DMZ | web‑critical‑intel | WooCommerce; Intel‑only HA |
| **web‑infra (CF Tunnel / Traefik / CrowdSec)** | VM | 1 | 1GB | DMZ | web‑infra | Can be moved to k8s later |

---

### Total Resource Use
- **vCPU declared:** 6–7  
- **RAM:** ~10–11GB  
- Fits within 12GB guest budget

---

# pve2 — Infra + Internal LXCs + Kubernetes Worker

### Role
- Host internal apps (Immich, Seafile, Stirling‑PDF)  
- Runs one k8s control plane + one worker  
- Hosts two small web VMs  
- AMD CPU → avoid migrating Intel‑pinned VMs here

---

### Virtual Machines

| Service | Type | vCPU | RAM | VLAN | HA Group | Notes |
|--------|------|------|------|-------|----------|-------|
| **k8s‑cp‑2** | VM | 1 | 2GB | Internal | k8s‑cp | Control plane node #2 |
| **k8s‑worker‑2** | VM | 2 | 4GB | Internal | k8s‑workers | Secondary worker |
| **web‑small‑1** | VM | 1 | 1GB | DMZ | web‑small | Public site |
| **web‑small‑2** | VM | 1 | 1GB | DMZ | web‑small | Public site |

---

### LXCs (Internal Only, via Tailscale)

| Service | Type | vCPU | RAM | VLAN | Notes |
|--------|------|------|------|-------|-------|
| **Immich** | LXC | 2 | 2GB | Internal | Heavy IO; indexing |
| **Seafile** | LXC | 1 | 1GB | Internal | File sync |
| **Stirling‑PDF** | LXC | 1 | 1GB | Internal | Lightweight |

---

### Total Resource Use
- **vCPU declared:** 7  
- **RAM:** ~12GB  
- Fully utilises node capacity

---

# pve3 — Secondary Web + Jellyfin + Kubernetes Control Plane

### Role
- Backup Intel node for web workloads  
- Runs Jellyfin (transcoding)  
- Runs one k8s control plane  
- Hosts two small web VMs

---

### Virtual Machines

| Service | Type | vCPU | RAM | VLAN | HA Group | Notes |
|--------|------|------|------|-------|----------|-------|
| **k8s‑cp‑3** | VM | 1 | 2GB | Internal | k8s‑cp | Control plane node #3 |
| **web‑small‑3** | VM | 1 | 1GB | DMZ | web‑small | Public site |
| **web‑small‑4** | VM | 1 | 1GB | DMZ | web‑small | Public site |

---

### LXCs

| Service | Type | vCPU | RAM | VLAN | Notes |
|--------|------|------|------|-------|-------|
| **Jellyfin** | LXC | 2 | 4GB | Internal | CPU‑bound transcoding |

---

### Total Resource Use
- **vCPU declared:** 5  
- **RAM:** ~8GB  
- ~4GB headroom for spikes

---

# Kubernetes Cluster Layout

| Node | vCPU | RAM | Role |
|------|------|------|------|
| **k8s‑cp‑1 (pve1)** | 1 | 2GB | Control plane |
| **k8s‑cp‑2 (pve2)** | 1 | 2GB | Control plane |
| **k8s‑cp‑3 (pve3)** | 1 | 2GB | Control plane |
| **k8s‑worker‑1 (pve1)** | 2 | 4GB | Primary worker |
| **k8s‑worker‑2 (pve2)** | 2 | 4GB | Secondary worker |

### Namespaces
- `prod` → public workloads  
- `test` → ephemeral apps  
- `infra` → CF tunnel, Traefik, CrowdSec, monitoring  

---

# Network Design

| VLAN | Purpose |
|------|---------|
| **VLAN 10 – MGMT** | Proxmox, Ceph, SSH |
| **VLAN 20 – DMZ** | Public web VMs, CF tunnel, Traefik |
| **VLAN 30 – Internal** | LXCs, Kubernetes internal traffic |
| **Tailscale** | Secure access to internal LXCs |

---

# HA Groups

| Group | Members | Purpose |
|--------|----------|----------|
| **web‑critical‑intel** | pve1 + pve3 | WooCommerce VM (Intel‑only migration) |
| **web‑small** | all nodes | Small sites |
| **k8s‑cp** | all nodes | Control plane HA |
| **k8s‑workers** | pve1 + pve2 | Worker nodes |

---

# Next Step

Once this architecture is confirmed, Terraform modules will be generated for:

- VM creation  
- LXC creation  
- Kubernetes node templates  
- HA group assignment  
- VLAN mapping  
- Ansible inventory output  


