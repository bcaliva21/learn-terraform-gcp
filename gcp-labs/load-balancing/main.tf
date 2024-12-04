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

resource "google_service_account" "nucleus" {
  account_id   = "service-account-id"
  display_name = "nucleus-service-account1"
}

#resource "google_compute_instance_template" "nucleus_jumphost" {
#  name        = "nucleus-instance-template1"
#  description = "This template is used to create nucleus jumphost instance."
#
#  labels = {
#    environment = "dev"
#  }

#  instance_description = "description assigned to instances"
#  machine_type         = "e2-micro"

#  scheduling {
#    automatic_restart   = true
#    on_host_maintenance = "MIGRATE"
#  }

// Create a new boot disk from an image
#  disk {
#    source_image = "debian-cloud/debian-11"
#    auto_delete  = true
#    boot         = true
#  }

#  network_interface {
#    network    = google_compute_network.nucleus.id
#    subnetwork = google_compute_subnetwork.nucleus.id
#  }
#
#  service_account {
#    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#    email  = google_service_account.nucleus.email
#    scopes = ["cloud-platform"]
#  }
#}

#resource "google_compute_instance_from_template" "nucleus_jumphost_instance" {
#  name = "nucleus-jumphost-instance"
#  zone = var.zone
#
#  source_instance_template = google_compute_instance_template.nucleus_jumphost.self_link_unique
#}

# Virtual Private Cloud
resource "google_compute_network" "nucleus" {
  name                    = "nucleus-xlb-network"
  provider                = google
  auto_create_subnetworks = false
}

# Backend subnet
resource "google_compute_subnetwork" "nucleus" {
  name          = "nucleus-xlb-subnet"
  provider      = google
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.nucleus.id
}

# Reserved IP address
resource "google_compute_global_address" "nucleus" {
  provider = google
  name     = "nucleus-xlb-static-ip"
}

# Forwarding rule
resource "google_compute_global_forwarding_rule" "nucleus" {
  name                  = "nucleus-xlb-forwarding-rule"
  provider              = google
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.nucleus.id
  ip_address            = google_compute_global_address.nucleus.id
}

# Http proxy
resource "google_compute_target_http_proxy" "nucleus" {
  name     = "nucleus-xlb-target-http-proxy"
  provider = google
  url_map  = google_compute_url_map.nucleus.id
}

# Url map
resource "google_compute_url_map" "nucleus" {
  name            = "nucleus-xlb-url-map"
  provider        = google
  default_service = google_compute_backend_service.nucleus.id
}

# Backend service with custrom request and response headers
resource "google_compute_backend_service" "nucleus" {
  name                  = "nucleus-xlb-backend-service"
  provider              = google
  protocol              = "HTTP"
  port_name             = "my-port"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 10
  enable_cdn            = true
  health_checks         = [google_compute_health_check.nucleus.id]
  backend {
    group           = google_compute_instance_group_manager.nucleus.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# Instance template
resource "google_compute_instance_template" "nucleus_webserver" {
  name        = "nucleus-instance-webserver"
  description = "This template is used to create nucleus webserver instance."
  tags        = ["allow-health-check"]

  labels = {
    environment = "dev"
  }

  instance_description = "Nucleus webserver"
  machine_type         = "e2-medium"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.nucleus.id
    subnetwork = google_compute_subnetwork.nucleus.id
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.nucleus.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = file("./startup.sh")

}

# Health check
resource "google_compute_health_check" "nucleus" {
  name     = "nucleus-xlb-health-check"
  provider = google

  tcp_health_check {
    port = "80"
  }
}

# Managed instance group (MIG)
resource "google_compute_instance_group_manager" "nucleus" {
  name     = "nucleus-xlb-mig"
  provider = google
  zone     = var.zone
  named_port {
    name = "my-port"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.nucleus_webserver.id
    name              = "primary"
  }
  base_instance_name = "vm"
  target_size        = 2
}

# Allow access from health check ranges
resource "google_compute_firewall" "nucleus" {
  name          = "nucleus-xlb-fw-allow-hc"
  provider      = google
  direction     = "INGRESS"
  network       = google_compute_network.nucleus.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }
  target_tags = ["allow-health-check"]
}

resource "google_compute_firewall" "allow-egress" {
  name               = "allow-egress-all"
  provider           = google
  direction          = "EGRESS" # Allow outgoing traffic
  network            = google_compute_network.nucleus.id
  destination_ranges = ["0.0.0.0/0"] # Allow traffic to any destination
  allow {
    protocol = "tcp"
    ports    = ["80", "443"] # Allow HTTP and HTTPS traffic
  }
  priority = 1000 # Lower number means higher priority
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"
  name    = "my-cloud-router"
  project = var.project
  network = google_compute_network.nucleus.id
  region  = var.region

  nats = [{
    name                               = "my-nat-gateway"
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      {
        name                    = google_compute_subnetwork.nucleus.id
        source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
      }
    ]
  }]

}
