wordpress_sites = {
  hantaweb = {
    node_name = "pve3"
    vmid      = 4011
    ip        = "10.0.40.11/24"
    gateway   = "10.0.40.1"
    vlan_id   = 40
    cores     = 3
    memory    = 4096
    disk_size = 40
    datastore = "ceph-storage"
  }
  petitsanglais = {
    node_name = "pve4"
    vmid      = 4012
    ip        = "10.0.40.12/24"
    gateway   = "10.0.40.1"
    vlan_id   = 40
    cores     = 1
    memory    = 1024
    disk_size = 20
    datastore = "ceph-storage"
  }
  hanta-assos = {
    node_name = "pve3"
    vmid      = 4013
    ip        = "10.0.40.13/24"
    gateway   = "10.0.40.1"
    vlan_id   = 40
    cores     = 1
    memory    = 1024
    disk_size = 20
    datastore = "ceph-storage"
  }
}
