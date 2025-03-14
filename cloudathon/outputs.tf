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
  value = google_compute_global_address.global_ip.address
}
