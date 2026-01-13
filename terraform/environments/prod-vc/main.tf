# terraform/environments/prod-vc/main.tf

module "gcp_network" {
  source = "../../modules/gcp/network"

  project_id    = var.gcp_project_id
  region        = var.instance_region
  network_name  = "${var.env_prefix}-vpc"
  subnet_name   = "${var.env_prefix}-subnet"
  ip_cidr_range = var.ip_cidr_range
}

module "gcp_firewall" {
  source = "../../modules/gcp/firewall"

  project_id   = var.gcp_project_id
  network_name = module.gcp_network.network_name
  target_tags  = [var.env_prefix]
}

module "gcp_nat" {
  source = "../../modules/gcp/nat"

  project_id    = var.gcp_project_id
  region        = var.instance_region
  network_id    = module.gcp_network.network_id
  subnetwork_id = module.gcp_network.subnetwork_id
  router_name   = "${var.env_prefix}-router"
  nat_name      = "${var.env_prefix}-nat-gateway"
}

module "gcp_vc" {
  source = "../../modules/gcp/instance"

  project_id    = var.gcp_project_id
  zone          = var.instance_zone
  instance_name = var.instance_name
  machine_type  = var.instance_machine_type
  subnetwork_id = module.gcp_network.subnetwork_id
  image         = var.instance_os_image
  tags          = [var.env_prefix]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  depends_on = [module.gcp_firewall, module.gcp_nat]
}


# --- Automated SSH Config Generation ---

resource "local_file" "ssh_config_entry" {
  content = <<-EOT
    # This file is managed by Terraform
    Host ${var.instance_name}
      ProxyCommand gcloud compute start-iap-tunnel %h 22 --project="lido-csm-validator" --zone="${var.instance_zone}" --listen-on-stdin
      User ${var.ssh_user}

      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null

    Host ${var.instance_host_name}
      ProxyCommand gcloud compute start-iap-tunnel %h 22 --project="lido-csm-validator" --zone="${var.instance_zone}" --listen-on-stdin
      User ethereum-vc
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  EOT

  filename = "/Users/jeongseup/.ssh/config.d/${var.instance_name}"
}
