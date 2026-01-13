# terraform/modules/gcp/nat/variables.tf

variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "region" {
  type        = string
  description = "The GCP region."
}

variable "network_id" {
  type        = string
  description = "The ID of the VPC network."
}

variable "subnetwork_id" {
  type        = string
  description = "The ID of the subnetwork to apply NAT to."
}

variable "router_name" {
  type        = string
  description = "The name for the Cloud Router."
}

variable "nat_name" {
  type        = string
  description = "The name for the Cloud NAT gateway."
}
