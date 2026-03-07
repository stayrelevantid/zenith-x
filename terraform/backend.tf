terraform {
  backend "gcs" {
    bucket  = "zenith-x-tfstate-44e5396b"
    prefix  = "terraform/state"
  }
}
