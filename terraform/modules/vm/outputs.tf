output "ip_address" {
  value = var.ip
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.this.vm_id
}
