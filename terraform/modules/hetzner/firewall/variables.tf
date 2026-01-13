# terraform/modules/hetzner/firewall/variables.tf

variable "firewall_name" {
  description = "The name of the firewall."
  type        = string
}

variable "rules" {
  description = "A list of firewall rules to apply."
  type = list(object({
    direction   = string
    protocol    = string
    port        = optional(string)
    source_ips  = optional(list(string))
    destination_ips = optional(list(string))
    description = optional(string)
  }))
  default = []
}