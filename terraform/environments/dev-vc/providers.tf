# terraform/environments/dev-vc/providers.tf

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.6"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
