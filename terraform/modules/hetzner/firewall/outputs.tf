# terraform/modules/hetzner/firewall/outputs.tf

output "firewall_id" {
  description = "The ID of the created firewall."
  value       = data.hcloud_firewall.this.id
}