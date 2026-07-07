resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl start qemu-guest-agent
      - systemctl enable qemu-guest-agent
    EOF
    
    file_name = "vendor-data-${var.hostname}.yaml"
  }
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
      # FIX: Pass the raw string variable instead of using the file() function
      keys     = [var.ssh_public_key_string] 
    }

    # Attach the cloud-init snippet to install the guest agent
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id
  }
}
