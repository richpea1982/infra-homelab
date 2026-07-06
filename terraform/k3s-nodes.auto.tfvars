k3s_nodes = {
  pve2 = {
    node_name = "k3s-1",
    vmid = 1061,
    ip = "10.0.10.61/24",
    gateway = "10.0.10.1",
    cores = 4, memory = 6144,
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve3 = {
    node_name = "k3s-2",
    vmid = 1062,
    ip = "10.0.10.62/24",
    gateway = "10.0.10.1",
    cores = 4, memory = 6144,
    disk_size = 40,
    datastore = "local-lvm"
  }
  pve4 = {
    node_name = "k3s-3",
    vmid = 1063,
    ip = "10.0.10.63/24",
    gateway = "10.0.10.1",
    cores = 2, memory = 5120,
    disk_size = 40,
    datastore = "local-lvm" 
  }
}
