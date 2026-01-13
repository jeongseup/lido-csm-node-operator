# terraform/environments/dev-node/variables.tf

variable "ssh_public_key" {
  description = "Content of the public SSH key for accessing the VM."
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "Username for SSH login."
  type        = string
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token."
  type        = string
  sensitive   = true
}

variable "hcloud_ssh_key_name" {
  description = "The name of the SSH key in the Hetzner Cloud console."
  type        = string
}

variable "node_server_firewall_name" {
  description = "The name of the firewall to be applied to the server."
  type        = string
}

variable "node_server_firewall_allow_list" {
  description = "List of IPv4 addresses allowed for SSH and other restricted ports."
  type        = list(string)
  default     = []
}

variable "node_server_name" {
  description = "The name of the server."
  type        = string
}

variable "node_host_name" {
  description = "The hostname of the node server."
  type        = string
}

variable "node_server_type" {
  description = "The type of the server."
  type        = string
}

variable "node_server_os_image" {
  description = "The OS image for the server."
  type        = string
}

variable "node_server_location" {
  description = "The location of the server."
  type        = string
}

variable "node_user_name" {
  description = "Username for the new user to be created on the server."
  type        = string
  default     = "jeongseup"
}

variable "local_ssh_config_path" {
  description = "Path to the local SSH config file to be generated."
  type        = string
  default     = "/Users/jeongseup/.ssh"
}