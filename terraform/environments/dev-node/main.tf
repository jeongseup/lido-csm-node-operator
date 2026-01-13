# terraform/environments/dev-node/main.tf

resource "hcloud_ssh_key" "default" {
  name       = var.hcloud_ssh_key_name
  public_key = var.ssh_public_key
}

# --- Firewall Definitions ---
module "tailscale_firewall" {
    source = "../../modules/hetzner/firewall"

  firewall_name = "firewall-tailscale"
  rules = [
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "any"
      source_ips  = ["100.0.0.0/8"]
      description = "Allow any port from Tailscale VPC"
    }
  ]
}

module "ssh_firewall" {
  source = "../../modules/hetzner/firewall"

  firewall_name = "firewall-ssh"
  rules = [
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "22"
      source_ips  = [for ip in var.node_server_firewall_allow_list : "${ip}/32"]
      description = "Allow SSH from allowed IPs"
    }
  ]
}

module "monitoring_firewall" {
  source = "../../modules/hetzner/firewall"

  firewall_name = "firewall-monitoring-ethereum"
  rules = [
    # Nethermind
    { direction = "in", protocol = "tcp", port = "8545", source_ips = [for ip in var.node_server_firewall_allow_list : "${ip}/32"], description = "Allow Nethermind RPC" },
    { direction = "in", protocol = "tcp", port = "6060", source_ips = [for ip in var.node_server_firewall_allow_list : "${ip}/32"], description = "Allow Nethermind Metrics" },
    # Lighthouse
    { direction = "in", protocol = "tcp", port = "5052", source_ips = [for ip in var.node_server_firewall_allow_list : "${ip}/32"], description = "Allow Lighthouse Beacon API" },
    { direction = "in", protocol = "tcp", port = "8008", source_ips = [for ip in var.node_server_firewall_allow_list : "${ip}/32"], description = "Allow Lighthouse Metrics" },
  ]
}

module "p2p_firewall" {
  source = "../../modules/hetzner/firewall"

  firewall_name = "firewall-p2p-ethereum"
  rules = [
    # Execution Client P2P
    { direction = "in", protocol = "tcp", port = "30303", source_ips = ["0.0.0.0/0", "::/0"], description = "Allow Nethermind P2P TCP" },
    { direction = "in", protocol = "udp", port = "30303", source_ips = ["0.0.0.0/0", "::/0"], description = "Allow Nethermind P2P UDP" },
    # Consensus Client P2P
    { direction = "in", protocol = "tcp", port = "9000", source_ips = ["0.0.0.0/0", "::/0"], description = "Allow Lighthouse P2P TCP" },
    { direction = "in", protocol = "udp", port = "9000", source_ips = ["0.0.0.0/0", "::/0"], description = "Allow Lighthouse P2P UDP" },
    { direction = "in", protocol = "udp", port = "9001", source_ips = ["0.0.0.0/0", "::/0"], description = "Allow Lighthouse P2P QUIC" },
    # Outbound
    { direction = "out", protocol = "tcp", port = "any", destination_ips = ["0.0.0.0/0", "::/0"], description = "Allow all outbound TCP" },
    { direction = "out", protocol = "udp", port = "any", destination_ips = ["0.0.0.0/0", "::/0"], description = "Allow all outbound UDP" },
    { direction = "out", protocol = "icmp", destination_ips = ["0.0.0.0/0", "::/0"], description = "Allow all outbound ICMP" },
  ]
}



# --- Node Instance ---

module "hetzner_node" {
  source = "../../modules/hetzner/instance"

  server_name = var.node_server_name
  image       = var.node_server_os_image
  server_type = var.node_server_type
  location    = var.node_server_location
  ssh_key_id  = hcloud_ssh_key.default.id
  # firewalls
  firewall_ids = [
    module.ssh_firewall.firewall_id,
    module.p2p_firewall.firewall_id,
    module.monitoring_firewall.firewall_id,
    module.tailscale_firewall.firewall_id,
  ]

  # cloud init
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    user_name      = var.node_user_name
    ssh_public_key = var.ssh_public_key
  })
  # --- 이 부분을 추가합니다 ---
  server_labels = {
    role = "${var.node_host_name}"
  }
}

# --- Automated SSH Config Generation ---

resource "local_file" "ssh_config_entry" {
  content = <<-EOT
    # This file is managed by Terraform
    Host ${var.node_server_name}
      HostName ${module.hetzner_node.server_ipv4}
      User ${var.node_user_name}

      # --- 개발 환경용 설정 ---
      # 1. known_hosts 파일에서 키 확인 안 함
      StrictHostKeyChecking no
      # 2. known_hosts 파일에 새 키를 기록하지도 않음
      UserKnownHostsFile /dev/null

    Host ${var.node_host_name}
      HostName ${module.hetzner_node.server_ipv4}
      User ethereum-node
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  EOT

  filename = "/Users/jeongseup/.ssh/config.d/${var.node_server_name}"
}
