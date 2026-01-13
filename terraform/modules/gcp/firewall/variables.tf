# terraform/modules/gcp/firewall/variables.tf

variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "network_name" {
  type        = string
  description = "The name of the VPC network to apply firewall rules to."
}

variable "target_tags" {
  type        = list(string)
  description = "A list of tags applied to instances to which this rule applies."
}
