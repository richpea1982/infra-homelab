locals {
  ssh_public_key = var.ssh_public_key != null ? var.ssh_public_key : (
    fileexists(pathexpand("~/.ssh/id_terraform.pub")) ? file(pathexpand("~/.ssh/id_terraform.pub")) : null
  )
}
