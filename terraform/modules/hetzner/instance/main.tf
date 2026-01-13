# Server Module
# Why: Encapsulates server creation and cloud-init configuration

resource "hcloud_server" "this" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  location    = var.location
  labels      = merge(var.server_labels, { "managed-by" = "terraform" })
  backups     = var.server_backups_enabled

  # Enable both IPv4 and IPv6
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
    ipv4         = var.server_ipv4
  }

  # Inject cloud-init configuration
  user_data = var.user_data

  # Attach the SSH key for initial access
  ssh_keys = [var.ssh_key_id]

  # Attach Hetzner Cloud Firewall if provided
  firewall_ids = var.firewall_ids
}

