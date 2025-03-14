# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Fixed Instance Group reference for Active Cluster
resource "google_compute_instance_group_named_port" "active_named_port" {
  provider = google.asia-south2
  group    = google_container_node_pool.active_nodes.instance_group_urls[0]
  name     = "http"
  port     = 80
  zone     = "asia-south2-a"
}

# Fixed Instance Group reference for Passive Cluster
resource "google_compute_instance_group_named_port" "passive_named_port" {
  provider = google.asia-south1
  group    = google_container_node_pool.passive_nodes.instance_group_urls[0]
  name     = "http"
  port     = 80
  zone     = "asia-south1-a"
}

# Fixed service type to LoadBalancer
resource "kubernetes_service" "hello_world_service_active" {
  provider = kubernetes.asia-south2
  metadata {
    name = "hello-world-service"
  }
  spec {
    selector = {
      app = "hello-world"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
    type = "LoadBalancer"
  }
}

# Dummy Secret for AlertManager fix
resource "kubernetes_secret" "alertmanager" {
  provider = kubernetes.asia-south2
  metadata {
    name      = "alertmanager"
    namespace = "gmp-system"
  }
  data = {
    "config.yaml" = "dummy-content"
  }
}

# Fixed Backend Service reference
resource "google_compute_backend_service" "gke_backend" {
  provider    = google.asia-south2
  name        = "gke-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_container_node_pool.active_nodes.instance_group_urls[0]
  }
  backend {
    group = google_container_node_pool.passive_nodes.instance_group_urls[0]
  }

  health_checks = [google_compute_health_check.gke_health_check.id]
}
