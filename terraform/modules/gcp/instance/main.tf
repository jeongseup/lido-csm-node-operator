# terraform/modules/gcp/instance/main.tf

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = var.subnetwork_id
    // No access_config block means no public IP
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = var.startup_script

  service_account {
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
}
