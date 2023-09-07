output "project_id" {
  description = "GCP project id"
  value       = module.project.project_id
}

output "region" {
  value       = var.region
  description = "Google Cloud region to deploy resources"
}

output "apigee_env_name" {
  description = "Apigee Environment name"
  value       = var.apigee_env_name
}

output "apigee_envgroup_name" {
  description = "Apigee Environment Group name"
  value       = var.apigee_envgroup_name
}

output "apigee_runtime" {
  description = "Generated hostname (nip.io encoded IP address)"
  value       = "https://${var.apigee_envgroup_name}.${module.nip-development-hostname.hostname}"
}

output "apigee_remote_namespace" {
  description = "Apigee remote namespace"
  value       = var.apigee_remote_namespace
}

output "apigee_remote_cert" {
  description = "Apigee remote certificate (base64 encoded)"
  value = data.external.apigee_remote_setup.result["apigee_remote_cert"]
}

output "apigee_remote_key" {
  description = "Apigee remote key (base64 encoded)"
  value = data.external.apigee_remote_setup.result["apigee_remote_key"]
}

output "apigee_remote_properties" {
  description = "Apigee remote properties (base64 encoded)"
  value = data.external.apigee_remote_setup.result["apigee_remote_properties"]
}

output "gke_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster name"
}

output "gke_cluster_location" {
  value       = google_container_cluster.primary.location
  description = "GKE Cluster location"
}
