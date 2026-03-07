output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  sensitive   = true
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}
