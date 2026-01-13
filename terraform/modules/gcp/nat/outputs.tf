# terraform/modules/gcp/nat/outputs.tf

output "router_name" {
  description = "The name of the Cloud Router."
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "The name of the Cloud NAT gateway."
  value       = google_compute_router_nat.this.name
}
