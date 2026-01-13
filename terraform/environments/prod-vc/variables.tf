# terraform/environments/prod-vc/variables.tf

# GCP Variables
variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "instance_region" {
  description = "GCP region for resources."
  type        = string
}

variable "instance_zone" {
  description = "GCP zone for the VM."
  type        = string
}

# Environment Variables
variable "env_prefix" {
  description = "Prefix for all resources in this environment (e.g., 'prod-vc')."
  type        = string
}

# Instance Variables
variable "instance_machine_type" {
  description = "GCP machine type for the instance."
  type        = string
}

# SSH Variables
variable "ssh_user" {
  description = "Username for SSH login (e.g., 'ubuntu')."
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key content as a string."
  type        = string
  sensitive   = true
}

variable "ip_cidr_range" {
  description = "The IP CIDR range for the subnet."
  type        = string
}

variable "instance_name" {
  description = "The name of the VM instance."
  type        = string
}

variable "instance_host_name" {
  description = "The hostname for created a new instance."
  type        = string
}

variable "instance_os_image" {
  description = "The OS image for the instance."
  type        = string
}
