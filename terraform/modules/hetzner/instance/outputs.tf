output "server_ipv4" {
  description = "Public IPv4 address"
  value       = hcloud_server.this.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.this.ipv6_address
}

output "server_id" {
  description = "Server ID"
  value       = hcloud_server.this.id
}

output "server_name" {
  description = "Server name"
  value       = hcloud_server.this.name
}

output "server_status" {
  description = "Server status"
  value       = hcloud_server.this.status
}

output "server_labels" {
  description = "Labels assigned to the server"
  value       = hcloud_server.this.labels
}

