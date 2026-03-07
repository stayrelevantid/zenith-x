variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
}

variable "gcp_sa_name" {
  description = "Name for the Google Service Account to be created"
  type        = string
  default     = "gke-workload-sa"
}
