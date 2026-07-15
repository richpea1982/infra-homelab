output "k3s_node_ips" {
  value = { for k, v in module.k3s_node : k => v.ip_address }
}

output "wordpress_site_ips" {
  value = {
    hantaweb      = module.wordpress_hantaweb.ip_address
    petitsanglais = module.wordpress_petitsanglais.ip_address
    hantaassos = module.wordpress_hantaassos.ip_address
  }
}
