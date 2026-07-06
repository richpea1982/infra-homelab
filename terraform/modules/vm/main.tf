resource "proxmox_virtual_environment_download_file" "debian_cloud" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.image_url
  file_name    = "debian-13-genericcloud-amd64.img"
  # checksum / checksum_algorithm recommended — pull SHA512SUMS from the same Debian dir
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.hostname
  node_name = var.node_name
  vm_id     = var.vmid

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id   # local only — never Ceph, etcd fsync sensitivity
    file_id      = proxmox_virtual_environment_download_file.debian_cloud.id
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }
    user_account {
      username = "ansible"
      keys     = [file(var.ssh_public_key)]
    }
    # user_data_file_id should point at a cloud-init snippet installing
    # + enabling qemu-guest-agent — base cloud image doesn't include it
  }
}
