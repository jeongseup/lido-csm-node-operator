# terraform/environments/dev-vc/outputs.tf

output "vc_private_ip" {
  description = "Private IP address of the GCP validator client."
  value       = module.gcp_vc.private_ip
}

output "vc_ssh_command" {
  description = "Command to SSH into the GCP validator client via IAP."
  value       = module.gcp_vc.ssh_command
}
