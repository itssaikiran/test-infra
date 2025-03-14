terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Provider for asia-south2 region (active)
provider "google" {
  alias       = "asia-south2"
  project     = "cloud-fusion-453613"
  region      = "asia-south2"
  credentials = file("path-to-service-account-key.json") # Ensure correct path
}

# Provider for asia-south1 region (passive)
provider "google" {
  alias       = "asia-south1"
  project     = "cloud-fusion-453613"
  region      = "asia-south1"
  credentials = file("path-to-service-account-key.json") # Ensure correct path
}

# Fetch GKE credentials dynamically
data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "asia-south2"
  host                   = "https://${google_container_cluster.active_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.active_cluster.master_auth[0].cluster_ca_certificate)
}

provider "kubernetes" {
  alias                  = "asia-south1"
  host                   = "https://${google_container_cluster.passive_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.passive_cluster.master_auth[0].cluster_ca_certificate)
}
