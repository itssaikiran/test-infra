# cloudathon/outputs.tf

output "active_cluster_endpoint" {
  value = google_container_cluster.active_cluster.endpoint
}

output "passive_cluster_endpoint" {
  value = google_container_cluster.passive_cluster.endpoint
}

output "postgres_primary_ip" {
  value = google_sql_database_instance.postgres_primary.ip_address[0].ip_address
}

output "postgres_replica_ip" {
  value = google_sql_database_instance.postgres_replica.ip_address[0].ip_address
}

output "load_balancer_ip" {
  value       = kubernetes_service.hello_world_service_active.status[0].load_balancer[0].ingress[0].ip
  description = "External IP of the Hello World app from Kubernetes LoadBalancer"
}

output "hello_world_url" {
  value       = "http://${kubernetes_service.hello_world_service_active.status[0].load_balancer[0].ingress[0].ip}"
  description = "URL to access the Hello World app"
}