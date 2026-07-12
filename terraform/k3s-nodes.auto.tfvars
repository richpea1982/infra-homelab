k3s_nodes = {
  pve2 = {
    node_name	= "pve2",
    vmid	= 1021,
    ip		= "10.0.20.21/24",
    gateway	= "10.0.20.1",
    vlan_id	= 20
    cores	= 3,
    memory	= 6144,
    disk_size	= 40,
    datastore	= "local-lvm"
  }
  pve3 = {
    node_name	= "pve3",
    vmid	= 1022,
    ip		= "10.0.20.22/24",
    gateway	= "10.0.20.1",
    vlan_id	= 20
    cores	= 3,
    memory	= 6144,
    disk_size	= 40,
    datastore	= "local-lvm"
  }
  pve4 = {
    node_name	= "pve4",
    vmid	= 1023,
    ip		= "10.0.20.23/24",
    gateway	= "10.0.20.1",
    vlan_id	= 20
    cores	= 3,
    memory	= 5120,
    disk_size	= 40,
    datastore	= "local-lvm" 
  }
}
