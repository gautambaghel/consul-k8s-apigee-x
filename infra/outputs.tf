output "project_id" {
  description = "GCP project id"
  value       = module.project.project_id
}

output "region" {
  value       = var.region
  description = "Google Cloud region to deploy resources"
}

output "apigee_hostname" {
  description = "Generated hostname (nip.io encoded IP address)"
  value       = module.nip-development-hostname.hostname
}

output "gke_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster name"
}

output "gke_cluster_location" {
  value       = google_container_cluster.primary.location
  description = "GKE Cluster location"
}


