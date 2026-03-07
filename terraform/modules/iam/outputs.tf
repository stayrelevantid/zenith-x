output "service_account_email" {
  description = "The email of the created Google Service Account"
  value       = google_service_account.workload_sa.email
}

output "service_account_name" {
  description = "The fully-qualified name of the created Google Service Account"
  value       = google_service_account.workload_sa.name
}
