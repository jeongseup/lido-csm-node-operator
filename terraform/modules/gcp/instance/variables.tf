# terraform/modules/gcp/instance/variables.tf

variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "zone" {
  type        = string
  description = "The GCP zone to create the instance in."
}

variable "instance_name" {
  type        = string
  description = "The name of the VM instance."
}

variable "machine_type" {
  type        = string
  description = "The machine type of the instance."
}

variable "subnetwork_id" {
  type        = string
  description = "The ID of the subnetwork to attach the instance to."
}

variable "image" {
  type        = string
  description = "The boot disk image for the instance."
}

variable "tags" {
  type        = list(string)
  description = "A list of network tags to apply to the instance."
  default     = []
}

variable "ssh_user" {
  type        = string
  description = "The username for the SSH key."
}

variable "ssh_public_key" {
  type        = string
  description = "The public SSH key content."
  sensitive   = true
}

variable "startup_script" {
  type        = string
  description = "The startup script to run on the instance."
  default     = null
}
