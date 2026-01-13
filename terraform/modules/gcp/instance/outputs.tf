# terraform/modules/gcp/instance/outputs.tf

output "instance_name" {
  description = "The name of the compute instance."
  value       = google_compute_instance.this.name
}

output "private_ip" {
  description = "The private IP address of the instance."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance via IAP tunnel."
  value       = "gcloud compute ssh ${var.instance_name} --zone ${var.zone} --project ${var.project_id} --tunnel-through-iap"
}
