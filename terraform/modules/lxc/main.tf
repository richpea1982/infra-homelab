resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vmid
  unprivileged  = var.unprivileged
  started       = true
  start_on_boot = true

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }

  # `nesting` stays false — no reason for a media-serving container to run
  # nested containers. `mount: ["nfs"]` is the one feature flag this module
  # actually needs: it's what lets an otherwise-unprivileged (or privileged)
  # container mount NAS exports from inside its own guest OS, sharing the
  # host kernel's NFS client rather than needing a Proxmox-level bind mount.
  features {
    nesting = false
    mount   = var.mount_nfs ? ["nfs"] : []
  }

  dynamic "device_passthrough" {
    for_each = var.device_passthrough
    content {
      path = device_passthrough.value.path
      uid  = device_passthrough.value.uid
      gid  = device_passthrough.value.gid
      mode = device_passthrough.value.mode
    }
  }
}
