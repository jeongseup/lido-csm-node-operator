variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "image" {
  description = "Operating system image"
  type        = string
}

variable "server_type" {
  description = "Server instance type"
  type        = string
}

variable "location" {
  description = "Datacenter location"
  type        = string
}

variable "server_ipv4" {
  description = "Specific IPv4 address to assign (optional)"
  type        = string
  default     = null
}

variable "server_labels" {
  description = "Labels to apply to the server"
  type        = map(string)
  default     = {}
}

variable "server_backups_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = null
}

variable "ssh_key_id" {
  description = "SSH key ID to attach"
  type        = string
}

variable "firewall_ids" {
  description = "A list of firewall IDs to attach to the server."
  type        = list(string)
}