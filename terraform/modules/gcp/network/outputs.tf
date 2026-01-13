# terraform/modules/gcp/network/outputs.tf

output "network_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.this.name
}

output "subnetwork_id" {
  description = "The ID of the subnetwork."
  value       = google_compute_subnetwork.this.id
}
