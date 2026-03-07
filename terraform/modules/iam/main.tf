# Create a Google Service Account (GSA)
resource "google_service_account" "workload_sa" {
  account_id   = var.gcp_sa_name
  display_name = "Service Account for GKE Workload Identity"
  project      = var.project_id
}

# Grant the GSA access to Secret Manager
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.workload_sa.email}"
}

# Allow the Kubernetes Service Account (KSA) to impersonate the GSA
# The KSA doesn't exist yet, we only bind the role based on the GKE Workload Identity format
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.workload_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    # Allow all KSAs in the "default" namespace to act as this GSA (for example purposes).
    # In a real environment, you'd restrict this to a specific namespace and KSA name.
    "serviceAccount:${var.project_id}.svc.id.goog[default/zenith-ksa]",
    "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-server]"
  ]
}
