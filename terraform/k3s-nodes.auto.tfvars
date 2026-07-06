k3s_nodes = {
  pve2 = {
    node_name = "pve1",
    vmid = 1021,
    ip = "10.0.10.21/24",
    gateway = "10.0.10.1",
    cores = 3, memory = 6144,
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve3 = {
    node_name = "pve2",
    vmid = 1022,
    ip = "10.0.10.22/24",
    gateway = "10.0.10.1",
    cores = 3, memory = 6144,
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve4 = {
    node_name = "pve3",
    vmid = 1023,
    ip = "10.0.10.23/24",
    gateway = "10.0.10.1",
    cores = 3, memory = 5120,
    disk_size = 40,
    datastore = "local-lvm" 
  }
}
