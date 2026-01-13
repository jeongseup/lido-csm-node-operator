# terraform/environments/dev-vc/variables.tf

variable "ssh_public_key" {
  description = "Content of the public SSH key for accessing the VM."
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "Username for SSH login."
  type        = string
  default     = "devops"
}

variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources."
  type        = string
  default     = "asia-northeast3" # Seoul
}

variable "gcp_zone" {
  description = "GCP zone for the VM."
  type        = string
  default     = "asia-northeast3-a"
}
