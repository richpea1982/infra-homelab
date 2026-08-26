# ==============================================================================
# STAGE 1: Parallel Deployment (Local Host Storage)
# ==============================================================================
# This block continues to deploy all 3 K3s nodes in parallel across pve2, 3, and 4
module "k3s_node" {
  source   = "./modules/vm"
  for_each = var.k3s_nodes

  hostname       = "k3s-${each.key}"
  node_name      = each.value.node_name
  vmid           = each.value.vmid
  ip             = each.value.ip
  gateway        = each.value.gateway
  vlan_id        = each.value.vlan_id
  cores          = each.value.cores
  memory         = each.value.memory
  disk_size      = each.value.disk_size
  datastore_id   = each.value.datastore
  ssh_public_key = local.ssh_public_key
}

# ==============================================================================
# STAGE 2: Serial Deployment (Ceph Pool - One at a Time)
# ==============================================================================

# First Ceph VM: Waits for all Stage 1 local K3s nodes to fully finish
module "wordpress_hantaweb" {
  source = "./modules/vm"

  hostname       = "hantaweb"
  node_name      = var.wordpress_sites["hantaweb"].node_name
  vmid           = var.wordpress_sites["hantaweb"].vmid
  ip             = var.wordpress_sites["hantaweb"].ip
  gateway        = var.wordpress_sites["hantaweb"].gateway
  vlan_id        = var.wordpress_sites["hantaweb"].vlan_id
  cores          = var.wordpress_sites["hantaweb"].cores
  memory         = var.wordpress_sites["hantaweb"].memory
  disk_size      = var.wordpress_sites["hantaweb"].disk_size
  datastore_id   = var.wordpress_sites["hantaweb"].datastore
  ssh_public_key = local.ssh_public_key

  # Enforce Stage 1 completion
  depends_on = [module.k3s_node]
}

# Second Ceph VM: Explicitly waits for hantaweb to completely finish first
module "wordpress_petitsanglais" {
  source = "./modules/vm"

  hostname       = "petitsanglais"
  node_name      = var.wordpress_sites["petitsanglais"].node_name
  vmid           = var.wordpress_sites["petitsanglais"].vmid
  ip             = var.wordpress_sites["petitsanglais"].ip
  gateway        = var.wordpress_sites["petitsanglais"].gateway
  vlan_id        = var.wordpress_sites["petitsanglais"].vlan_id
  cores          = var.wordpress_sites["petitsanglais"].cores
  memory         = var.wordpress_sites["petitsanglais"].memory
  disk_size      = var.wordpress_sites["petitsanglais"].disk_size
  datastore_id   = var.wordpress_sites["petitsanglais"].datastore
  ssh_public_key = local.ssh_public_key

  # Enforce serial order within Stage 2 to protect Ceph IOPS
  depends_on = [module.wordpress_hantaweb]
}

# Second Ceph VM: Explicitly waits for petitsanglais to completely finish first
module "wordpress_hantaassos" {
  source = "./modules/vm"

  hostname       = "hanta-assos"
  node_name      = var.wordpress_sites["hanta-assos"].node_name
  vmid           = var.wordpress_sites["hanta-assos"].vmid
  ip             = var.wordpress_sites["hanta-assos"].ip
  gateway        = var.wordpress_sites["hanta-assos"].gateway
  vlan_id        = var.wordpress_sites["hanta-assos"].vlan_id
  cores          = var.wordpress_sites["hanta-assos"].cores
  memory         = var.wordpress_sites["hanta-assos"].memory
  disk_size      = var.wordpress_sites["hanta-assos"].disk_size
  datastore_id   = var.wordpress_sites["hanta-assos"].datastore
  ssh_public_key = local.ssh_public_key

  # Enforce serial order within Stage 2 to protect Ceph IOPS
  depends_on = [module.wordpress_petitsanglais]
}

# ==============================================================================
# Append this block to your existing terraform/main.tf
# ==============================================================================

resource "proxmox_virtual_environment_download_file" "debian_13_lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve2"
  url          = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
}

module "media_lxc" {
  source   = "./modules/lxc"
  for_each = var.media_lxc

  hostname            = each.value.hostname
  node_name           = each.value.node_name
  vmid                = each.value.vmid
  unprivileged        = each.value.unprivileged
  cores               = each.value.cores
  memory              = each.value.memory
  disk_size           = each.value.disk_size
  datastore_id        = each.value.datastore
  ip                  = each.value.ip
  gateway             = each.value.gateway
  vlan_id             = each.value.vlan_id
  ssh_public_key      = local.ssh_public_key
  template_file_id    = proxmox_virtual_environment_download_file.debian_13_lxc_template.id
  mount_nfs           = true
  device_passthrough  = each.value.device_passthrough
}

# null_resource.media_lxc_post_config — delete entirely

resource "null_resource" "media_lxc_post_config" {
  for_each = var.media_lxc

  depends_on = [module.media_lxc]

  triggers = {
    vmid = module.media_lxc[each.key].vm_id
    mac  = module.media_lxc[each.key].mac_address
  }

  connection {
    type        = "ssh"
    host        = "10.0.10.12"
    user        = "root"
    private_key = base64decode(var.ssh_private_key_base64)
  }

  provisioner "remote-exec" {
    inline = concat(
      ["pct set ${module.media_lxc[each.key].vm_id} --features nesting=0,mount=nfs"],
      [
        for idx, dev in each.value.device_passthrough :
        "pct set ${module.media_lxc[each.key].vm_id} -dev${idx} path=${dev.path}"
      ],
      # Feature/config changes (mount permissions especially) are applied
      # to a privileged container's AppArmor/cgroup profile at start time,
      # not hot-reloaded into an already-running container. pct set writes
      # the config correctly but the running instance won't reflect it
      # until restarted — confirmed the hard way on the Jellyfin container
      # (mount=nfs was present in `pct config` but NFS mounts didn't work
      # until a manual restart).
      ["pct reboot ${module.media_lxc[each.key].vm_id}"]
    )
  }
}
