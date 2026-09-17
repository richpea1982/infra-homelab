provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    username    = "root"
    private_key = base64decode(var.ssh_private_key_base64)
  }
}

