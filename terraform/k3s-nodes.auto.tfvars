# Replace the memory values in your existing terraform/k3s-nodes.auto.tfvars
# with these. +1GB on pve2/pve3, +1GB on pve4 (kept smaller since pve4 has
# only 12GB total host RAM vs 16GB on pve2/pve3 — less headroom over
# Proxmox+Ceph overhead).
#
# VERIFY BEFORE APPLYING: this assumes current free RAM on each host after
# existing VMs/LXCs (including the now-departed Photoprism LXC's 6GB
# reservation on pve2, which is fully freed by this change) and the Ceph
# OSD daemon's own memory footprint (~1GB/OSD is typical for HDD-backed
# OSDs at this scale, but confirm via `free -h` per host before applying,
# not just this comment's assumption).

k3s_nodes = {
  pve2 = {
    node_name = "pve2",
    vmid      = 2021,
    ip        = "10.0.20.21/24",
    gateway   = "10.0.20.1",
    vlan_id   = 20
    cores     = 3,
    memory    = 7168, # was 6144
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve3 = {
    node_name = "pve3",
    vmid      = 2022,
    ip        = "10.0.20.22/24",
    gateway   = "10.0.20.1",
    vlan_id   = 20
    cores     = 3,
    memory    = 7168, # was 6144
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve4 = {
    node_name = "pve4",
    vmid      = 2023,
    ip        = "10.0.20.23/24",
    gateway   = "10.0.20.1",
    vlan_id   = 20
    cores     = 3,
    memory    = 7168, # was 5120
    disk_size = 40,
    datastore = "local-lvm"
  }
}
