# ==============================================================================
# Append this block to your existing terraform/main.tf
# ==============================================================================

# Debian 13 LXC template — separate content_type ("vztmpl") from the VM
# module's qcow2 download. Both media containers live on pve2, so one
# download covers both.
resource "proxmox_virtual_environment_download_file" "debian_13_lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve2"
  url          = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"

  # Point-release filename WILL drift (13.0-1 -> 13.1-1 -> 13.1-2 already
  # seen across 2025-2026). If this 404s, run `pveam update` on pve2 then
  # `pveam available -section system | grep debian` to get the current
  # filename before touching anything else — same class of issue as the
  # still-open SHA512 checksum TODO on the VM module's image download.
}

module "media_lxc" {
  source   = "./modules/lxc"
  for_each = var.media_lxc

  hostname           = each.value.hostname
  node_name          = each.value.node_name
  vmid               = each.value.vmid
  unprivileged       = each.value.unprivileged
  cores              = each.value.cores
  memory             = each.value.memory
  disk_size          = each.value.disk_size
  datastore_id       = each.value.datastore
  ip                 = each.value.ip
  gateway            = each.value.gateway
  vlan_id            = each.value.vlan_id
  ssh_public_key     = local.ssh_public_key
  template_file_id   = proxmox_virtual_environment_download_file.debian_13_lxc_template.id
  mount_nfs          = true
  device_passthrough = each.value.device_passthrough
}
