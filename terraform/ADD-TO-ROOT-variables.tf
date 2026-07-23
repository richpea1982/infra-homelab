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
