k3s_nodes = {
  pve2 = { node_name = "pve2", vmid = 220, ip = "10.0.10.20/24", gateway = "10.0.10.1", cores = 4, memory = 8192, disk_size = 40, datastore = "local-lvm" }
  pve3 = { node_name = "pve3", vmid = 221, ip = "10.0.10.21/24", gateway = "10.0.10.1", cores = 4, memory = 4096, disk_size = 40, datastore = "local-lvm" }
  pve4 = { node_name = "pve4", vmid = 222, ip = "10.0.10.22/24", gateway = "10.0.10.1", cores = 2, memory = 4096, disk_size = 40, datastore = "local-lvm" }
}
