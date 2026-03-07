# Custom VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project}-vpc-${var.env}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "${var.project}-subnet-${var.env}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = "10.0.0.0/16"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = "${var.project}-router-${var.env}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project}-nat-${var.env}"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
