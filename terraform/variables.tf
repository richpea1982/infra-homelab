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
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
