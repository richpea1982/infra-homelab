wordpress_sites = {
  hantaweb = {
    node_name = "pve3"
    vmid      = 310
    ip        = "10.20.0.13/24"
    gateway   = "10.20.0.1"
    cores     = 2
    memory    = 2048
    disk_size = 20
    datastore = "local-lvm"
  }
  petitsanglais = {
    node_name = "pve4"
    vmid      = 311
    ip        = "10.20.0.11/24"
    gateway   = "10.20.0.1"
    cores     = 2
    memory    = 2048
    disk_size = 20
    datastore = "local-lvm"
  }
}
