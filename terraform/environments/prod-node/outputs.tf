# terraform/environments/dev-node/outputs.tf

output "node_server_name" {
  description = "Name of the Hetzner node server."
  value       = module.hetzner_node.server_name
}

output "node_public_ip" {
  description = "Public IPv4 address of the Hetzner node."
  value       = module.hetzner_node.server_ipv4
}

output "node_public_ipv6" {
  description = "Public IPv6 address of the Hetzner node."
  value       = module.hetzner_node.server_ipv6
}

output "node_server_id" {
  description = "The ID of the server."
  value       = module.hetzner_node.server_id
}

output "node_server_status" {
  description = "The status of the server."
  value       = module.hetzner_node.server_status
}

output "ssh_key_name" {
  description = "The name of the SSH key."
  value       = data.hcloud_ssh_key.default.name
}

output "ssh_key_fingerprint" {
  description = "The fingerprint of the SSH key."
  value       = data.hcloud_ssh_key.default.fingerprint
}

output "node_server_labels" {
  description = "Labels assigned to the Hetzner node server."
  value       = module.hetzner_node.server_labels
}
