# Hetzner Cloud Firewall Module
# Why: Centralized network-level firewall configuration for Ethereum validators

data "hcloud_firewall" "this" {
  name = var.firewall_name
}

