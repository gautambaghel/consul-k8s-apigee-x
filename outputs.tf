output "project_id" {
  description = "GCP project id"
  value       = module.project.project_id
}

output "region" {
  value       = var.region
  description = "Google Cloud region to deploy resources"
}

output "apigee_endpoint" {
  description = "Generated hostname (nip.io encoded IP address)"
  value       = module.nip-development-hostname.hostname
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}
