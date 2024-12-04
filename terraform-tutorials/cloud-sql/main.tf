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

resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name             = "my-database-instance"
  region           = var.region
  database_version = "POSTGRES_16"
  settings {
    tier = "db-perf-optimized-N-2"
  }

  deletion_protection = false
}

resource "google_sql_user" "users" {
  name     = "me"
  instance = google_sql_database_instance.instance.name
  password = "123"
}
