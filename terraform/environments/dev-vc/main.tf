# terraform/environments/dev-vc/main.tf

module "gcp_network" {
  source = "../../../modules/gcp/network"

  project_id    = var.gcp_project_id
  region        = var.gcp_region
  network_name  = "dev-vc-vpc"
  subnet_name   = "dev-vc-subnet"
  ip_cidr_range = "10.20.0.0/24"
}

module "gcp_firewall" {
  source = "../../../modules/gcp/firewall"

  project_id   = var.gcp_project_id
  network_name = module.gcp_network.network_name
  target_tags  = ["dev-vc"]
}

module "gcp_nat" {
  source = "../../../modules/gcp/nat"

  project_id    = var.gcp_project_id
  region        = var.gcp_region
  network_id    = module.gcp_network.network_id
  subnetwork_id = module.gcp_network.subnetwork_id
  router_name   = "dev-vc-router"
  nat_name      = "dev-vc-nat-gateway"
}

module "gcp_vc" {
  source = "../../../modules/gcp/instance"

  project_id    = var.gcp_project_id
  zone          = var.gcp_zone
  instance_name = "dev-vc-gcp"
  machine_type  = "e2-micro"
  subnetwork_id = module.gcp_network.subnetwork_id
  tags          = ["dev-vc"]

  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key

  depends_on = [module.gcp_firewall, module.gcp_nat]
}
