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
# Using google_service_account_iam_member (non-authoritative) to avoid conflicts
resource "google_service_account_iam_member" "gke_ksa_binding" {
  service_account_id = google_service_account.workload_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/zenith-ksa]"
}

resource "google_service_account_iam_member" "argocd_binding" {
  service_account_id = google_service_account.workload_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-server]"
}

resource "google_service_account_iam_member" "eso_binding" {
  service_account_id = google_service_account.workload_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
}
