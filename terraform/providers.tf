provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  # ADD THIS BLOCK:
  ssh {
#    agent    = true
    username = "root"
    private_key = var.proxmox_ssh_private_key
  }
}

