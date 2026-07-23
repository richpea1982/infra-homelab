variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "k3s_nodes" {
  description = "K3s cluster nodes (embedded etcd, all schedulable)"
  type = map(object({
    node_name = string   # target Proxmox host: pve2/pve3/pve4
    vmid      = number
    ip        = string   # CIDR, e.g. 10.0.10.20/24
    gateway   = string
    vlan_id   = number
    cores     = number
    memory    = number
    disk_size = number
    datastore = string   # local storage only — never Ceph (etcd fsync sensitivity)
  }))
}

variable "wordpress_sites" {
  description = "WordPress sites — full VMs, not LXCs (highest-risk workload gets hypervisor isolation)"
  type = map(object({
    node_name = string
    vmid      = number
    ip        = string
    gateway   = string
    vlan_id   = number
    cores     = number
    memory    = number
    disk_size = number
    datastore = string
  }))
}
# ssh public key injection
variable "ssh_public_key" {
  type    = string
  default = null
}
variable "ssh_private_key_base64" {
  type        = string
  description = "Base64 encoded private SSH key passed from Semaphore secrets"
  sensitive   = true
}
# ==============================================================================
# Append this block to your existing terraform/variables.tf
# ==============================================================================

variable "media_lxc" {
  description = "Media-serving LXCs on pve2 — Jellyfin (privileged, iGPU passthrough) and Photoprism (unprivileged, no passthrough)."
  type = map(object({
    hostname     = string
    node_name    = string
    vmid         = number
    unprivileged = bool
    cores        = number
    memory       = number
    disk_size    = number
    datastore    = string
    ip           = string
    gateway      = string
    vlan_id      = number
    device_passthrough = list(object({
      path = string
    }))
  }))
}
