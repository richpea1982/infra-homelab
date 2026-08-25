output "ip_address" {
  value = var.ip
}

output "vm_id" {
  value = proxmox_virtual_environment_container.this.vm_id
}

output "mac_address" {
  value = proxmox_virtual_environment_container.this.network_interface[0].mac_address
}
