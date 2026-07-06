wordpress_sites = {
  hantaweb = {
    node_name = "pve3"
    vmid      = 2021
    ip        = "10.0.20.21/24"
    gateway   = "10.0.20.1"
    cores     = 2
    memory    = 2048
    disk_size = 40
    datastore = "local-lvm"
  }
  petitsanglais = {
    node_name = "pve4"
    vmid      = 2022
    ip        = "10.0.20.22/24"
    gateway   = "10.0.20.1"
    cores     = 2
    memory    = 2048
    disk_size = 20
    datastore = "local-lvm"
  }
}
