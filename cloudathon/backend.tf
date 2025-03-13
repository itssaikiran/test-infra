terraform {
  backend "gcs" {
    bucket = "cloudathon-vdc1"
    prefix = "terraform/state"
  }
}
