output "workload_identity_provider" {
  description = "WIF Provider resource name — use as WIF_PROVIDER GitHub Secret"
  value = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Service Account email — use as WIF_SERVICE_ACCOUNT GitHub Secret"
  value = var.service_account_email
}
