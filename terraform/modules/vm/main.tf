# 1. This resource handles downloading the Debian 13 Cloud Image to Proxmox
resource "proxmox_virtual_environment_download_file" "debian_cloud" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.image_url
  
  file_name    = "debian-13-${var.hostname}.img" 
}

# 2. This resource generates the Cloud-Init script text on the fly
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

# 3. This resource provisions the VM and ties everything together
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

  # OS Root Disk Layout (Only ONE copy needed)
  disk {
    datastore_id = var.datastore_id   
    file_id      = proxmox_virtual_environment_download_file.debian_cloud.id
    interface    = "scsi0"
    size         = var.disk_size
  }

  # Cloud-Init Drive Layout (Tells Proxmox to mount the CD-ROM ISO for config)
  disk {
    datastore_id = var.datastore_id
    interface    = "ide2"
    file_format  = "raw"
    type         = "cloudinit"
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
      username = "rich"
      keys     = [var.ssh_public_key] 
    }

    # Attach the cloud-init snippet to install the guest agent
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id
  }
}
