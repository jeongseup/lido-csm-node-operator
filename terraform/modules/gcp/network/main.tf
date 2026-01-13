# terraform/modules/gcp/network/main.tf

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  project       = var.project_id
  name          = var.subnet_name
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.this.id
}
