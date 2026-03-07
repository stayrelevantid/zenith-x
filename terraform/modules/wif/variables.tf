variable "project_id" {
  type = string
}

variable "github_org" {
  description = "GitHub organization or username (e.g. stayrelevantid)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. zenith-x)"
  type        = string
}

variable "service_account_email" {
  description = "GCP Service Account email to impersonate via WIF"
  type        = string
}
