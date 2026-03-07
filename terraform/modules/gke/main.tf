# GKE Standard Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project}-cluster-${var.env}"
  project  = var.project_id
  location = var.region # Regional cluster

  # We can't create a cluster with no node pool defined, but we want to only use
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    disk_type = "pd-standard"
  }

  deletion_protection = false

  network    = var.vpc_name
  subnetwork = var.subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  resource_labels = var.labels

  # For Standard clusters, release channel
  release_channel {
    channel = "REGULAR"
  }

  lifecycle {
    ignore_changes = [
      node_config,
      resource_labels,
    ]
  }
}

# Spot VM Node Pool
resource "google_container_node_pool" "spot_node_pool" {
  name       = "${var.project}-spot-pool-${var.env}"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    spot         = true
    machine_type = "e2-medium"
    disk_type    = "pd-standard"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = merge(var.labels, {
      env = var.env
    })

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Ignore changes around node count as it might be managed by autoscaler later if enabled
  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config[0].labels,
      node_config[0].resource_labels,
    ]
  }
}
