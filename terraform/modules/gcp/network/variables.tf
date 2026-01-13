# terraform/modules/gcp/network/variables.tf

variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy to."
}

variable "region" {
  type        = string
  description = "The GCP region to deploy to."
}

variable "network_name" {
  type        = string
  description = "The name of the VPC network."
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnetwork."
}

variable "ip_cidr_range" {
  type        = string
  description = "The IP CIDR range for the subnetwork."
}
