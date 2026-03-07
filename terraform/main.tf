locals {
  common_labels = {
    project = var.project
    env     = var.env
  }
}

# Enable required APIs
resource "google_project_service" "crm_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.crm_api]
}

resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.crm_api]
}

resource "google_project_service" "secretmanager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.crm_api]
}

resource "google_project_service" "artifactregistry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.crm_api]
}

# VPC Module
module "vpc" {
  source     = "./modules/vpc"
  project_id = var.project_id
  region     = var.region
  env        = var.env
  project    = var.project
  labels     = local.common_labels

  depends_on = [google_project_service.compute_api]
}

# GKE Module
module "gke" {
  source      = "./modules/gke"
  project_id  = var.project_id
  region      = var.region
  vpc_name    = module.vpc.network_name
  subnet_name = module.vpc.subnet_name
  env         = var.env
  project     = var.project
  labels      = local.common_labels

  depends_on = [google_project_service.container_api, module.vpc]
}

# IAM Module (Workload Identity)
module "iam" {
  source       = "./modules/iam"
  project_id   = var.project_id
  cluster_name = module.gke.cluster_name
  gcp_sa_name  = "${var.project}-gke-sa"

  depends_on = [module.gke]
}

# Google Secret Manager
resource "google_secret_manager_secret" "example_secret" {
  project   = var.project_id
  secret_id = "${var.project}-secret"
  labels    = local.common_labels
  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

# Google Artifact Registry
resource "google_artifact_registry_repository" "gar" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.project}-registry"
  description   = "Docker repository for ${var.project}"
  format        = "DOCKER"
  labels        = local.common_labels

  depends_on = [google_project_service.artifactregistry_api]
}
