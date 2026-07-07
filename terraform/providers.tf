provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  # ADD THIS BLOCK:
  ssh {
    agent    = true
    username = "root"  # Fixes the empty user "" issue
  }
}

