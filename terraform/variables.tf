variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "asia-southeast2" # Jakarta region
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "testing"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "zenith-x"
}
