terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_cloud_run_v2_service" "default" {
  client              = "terraform"
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  location            = var.region
  name                = "cloudrun-service"

  template {
    containers {
      image = "us-dcker.pkg.dev/cloudrun/containers/hello"
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
