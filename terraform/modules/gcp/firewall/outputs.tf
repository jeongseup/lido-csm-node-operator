# terraform/modules/gcp/firewall/outputs.tf

output "allow_ssh_via_iap_name" {
  description = "Name of the IAP SSH firewall rule."
  value       = google_compute_firewall.allow_ssh_via_iap.name
}

output "allow_egress_name" {
  description = "Name of the egress firewall rule."
  value       = google_compute_firewall.allow_egress.name
}
