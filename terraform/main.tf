module "k3s_node" {
  source   = "./modules/vm"
  for_each = var.k3s_nodes

  hostname       = "k3s-${each.key}"
  node_name      = each.value.node_name
  vmid           = each.value.vmid
  ip             = each.value.ip
  gateway        = each.value.gateway
  cores          = each.value.cores
  memory         = each.value.memory
  disk_size      = each.value.disk_size
  datastore_id   = each.value.datastore
  ssh_public_key = var.ssh_public_key
}

module "wordpress_site" {
  source   = "./modules/vm"
  for_each = var.wordpress_sites

  hostname       = each.key
  node_name      = each.value.node_name
  vmid           = each.value.vmid
  ip             = each.value.ip
  gateway        = each.value.gateway
  cores          = each.value.cores
  memory         = each.value.memory
  disk_size      = each.value.disk_size
  datastore_id   = each.value.datastore
  ssh_public_key = var.ssh_public_key
}
