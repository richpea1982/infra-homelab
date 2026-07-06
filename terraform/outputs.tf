output "k3s_node_ips" {
  value = { for k, v in module.k3s_node : k => v.ip_address }
}

output "wordpress_site_ips" {
  value = { for k, v in module.wordpress_site : k => v.ip_address }
}
