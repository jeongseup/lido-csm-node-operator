
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
  region  = var.instance_region
}
