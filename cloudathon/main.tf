# cloudathon/main.tf

# Active GKE Cluster in asia-south2
resource "google_container_cluster" "active_cluster" {
  provider                 = google.asia-south2
  name                     = "active-gke-cluster"
  location                 = "asia-south2-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = "default"
  subnetwork               = "default"
  deletion_protection      = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "active_nodes" {
  provider   = google.asia-south2
  name       = "active-node-pool"
  cluster    = google_container_cluster.active_cluster.name
  location   = "asia-south2-a"
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    preemptible  = true
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  depends_on = [google_container_cluster.active_cluster]
}

# Passive GKE Cluster in asia-south1
resource "google_container_cluster" "passive_cluster" {
  provider                 = google.asia-south1
  name                     = "passive-gke-cluster"
  location                 = "asia-south1-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = "default"
  subnetwork               = "default"
  deletion_protection      = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "passive_nodes" {
  provider   = google.asia-south1
  name       = "passive-node-pool"
  cluster    = google_container_cluster.passive_cluster.name
  location   = "asia-south1-a"
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    preemptible  = true
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  depends_on = [google_container_cluster.passive_cluster]
}

# Cloud SQL PostgreSQL Primary Instance
resource "google_sql_database_instance" "postgres_primary" {
  provider            = google.asia-south2
  name                = "postgres-primary"
  region              = "asia-south2"
  database_version    = "POSTGRES_15"
  deletion_protection = false

  settings {
    tier              = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size         = 10

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "gke-clusters"
        value = "0.0.0.0/0"
      }
    }
  }
}

# Cloud SQL PostgreSQL Read Replica
resource "google_sql_database_instance" "postgres_replica" {
  provider             = google.asia-south1
  name                 = "postgres-replica"
  region               = "asia-south1"
  database_version     = "POSTGRES_15"
  deletion_protection  = false
  master_instance_name = google_sql_database_instance.postgres_primary.name

  settings {
    tier              = "db-g1-small"
    availability_type = "ZONAL"
    disk_size         = 10

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "gke-clusters"
        value = "0.0.0.0/0"
      }
    }
  }
}

# Global Load Balancer
resource "google_compute_global_address" "global_ip" {
  provider = google.asia-south2
  name     = "gke-global-ip"
}

resource "google_compute_global_forwarding_rule" "gke_forwarding_rule" {
  provider   = google.asia-south2
  name       = "gke-forwarding-rule"
  target     = google_compute_target_http_proxy.gke_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.global_ip.address
}

resource "google_compute_target_http_proxy" "gke_proxy" {
  provider   = google.asia-south2
  name       = "gke-http-proxy"
  url_map    = google_compute_url_map.gke_url_map.id
}

resource "google_compute_url_map" "gke_url_map" {
  provider        = google.asia-south2
  name            = "gke-url-map"
  default_service = google_compute_backend_service.gke_backend.id
}

resource "google_compute_backend_service" "gke_backend" {
  provider    = google.asia-south2
  name        = "gke-backend-service"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_container_node_pool.active_nodes.instance_group_urls[0]
  }

  backend {
    group = google_container_node_pool.passive_nodes.instance_group_urls[0]
  }

  health_checks = [google_compute_health_check.gke_health_check.id]
}

resource "google_compute_health_check" "gke_health_check" {
  provider = google.asia-south2
  name     = "gke-health-check"

  http_health_check {
    port         = 80
    request_path = "/"
  }

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}
