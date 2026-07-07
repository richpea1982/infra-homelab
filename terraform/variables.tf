variable "proxmox_ssh_private_key" {
  type      = string
  sensitive = true
}
variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "k3s_nodes" {
  description = "K3s cluster nodes (embedded etcd, all schedulable)"
  type = map(object({
    node_name = string   # target Proxmox host: pve2/pve3/pve4
    vmid      = number
    ip        = string   # CIDR, e.g. 10.0.10.20/24
    gateway   = string
    cores     = number
    memory    = number
    disk_size = number
    datastore = string   # local storage only — never Ceph (etcd fsync sensitivity)
  }))
}

variable "wordpress_sites" {
  description = "WordPress sites — full VMs, not LXCs (highest-risk workload gets hypervisor isolation)"
  type = map(object({
    node_name = string
    vmid      = number
    ip        = string
    gateway   = string
    cores     = number
    memory    = number
    disk_size = number
    datastore = string
  }))
}

variable "ssh_public_key" {
  type        = string
  description = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1D/ll0wCK3OkjnREp0DxGY23+ELAV5jv6pM3GZarkI root@automation-node"
  # You can safely set a default here since public keys are not sensitive, 
  # or pass it in via your .tfvars file.
}
