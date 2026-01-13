# terraform/modules/gcp/nat/main.tf

resource "google_compute_router" "this" {
  project = var.project_id
  name    = var.router_name
  region  = var.region
  network = var.network_id
}

resource "google_compute_router_nat" "this" {
  project                            = var.project_id
  name                               = var.nat_name
  router                             = google_compute_router.this.name
  region                             = google_compute_router.this.region
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "AUTO_ONLY"

  subnetwork {
    name                    = var.subnetwork_id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
