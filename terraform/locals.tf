locals {
  ssh_public_key = coalesce(var.ssh_public_key, file(pathexpand("~/.ssh/id_terraform.pub")))
}
