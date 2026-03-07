variable "project_id" {
  type    = string
  default = "stayrelevantid"
}

variable "region" {
  type    = string
  default = "asia-southeast2"
}

variable "project" {
  type    = string
  default = "zenith-x"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project}-tfstate-${random_id.bucket_suffix.hex}"
  force_destroy = true
  location      = "ASIA"
  storage_class = "STANDARD"
  
  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = "" # Use Google-managed key
  }
}

output "tfstate_bucket_name" {
  value = google_storage_bucket.terraform_state.name
}
