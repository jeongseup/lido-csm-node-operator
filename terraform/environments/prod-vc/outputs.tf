# terraform/environments/dev-vc/outputs.tf

output "vc_private_ip" {
  description = "Private IP address of the GCP validator client."
  value       = module.gcp_vc.private_ip
}

output "vc_ssh_command" {
  description = "Command to SSH into the GCP validator client via IAP."
  value       = module.gcp_vc.ssh_command
}

output "instance_type" {
  description = "GCP machine type for the instance."
  value       = var.instance_machine_type
}

output "instance_region" {
  description = "GCP region for resources."
  value       = var.instance_region
}

output "network_name" {
  description = "The name of the VPC network."
  value       = module.gcp_network.network_name
}

output "subnetwork_id" {
  description = "The ID of the subnetwork."
  value       = module.gcp_network.subnetwork_id
}

output "router_name" {
  description = "The name of the Cloud Router."
  value       = module.gcp_nat.router_name
}

output "nat_name" {
  description = "The name of the Cloud NAT gateway."
  value       = module.gcp_nat.nat_name
}