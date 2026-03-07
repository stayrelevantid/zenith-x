output "network_name" {
  description = "The name of the VPC being created"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The name of the private subnet being created"
  value       = google_compute_subnetwork.private_subnet.name
}

output "network_id" {
  description = "The ID of the VPC being created"
  value       = google_compute_network.vpc.id
}
