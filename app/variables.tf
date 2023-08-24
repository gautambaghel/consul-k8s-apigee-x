variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "region" {
  description = "GCP region for non Apigee resources."
  default     = "us-west1"
}

variable "helm_config" {
  description = "HashiCorp Consul Helm chart configuration"
  type        = any
  default     = {}
}

variable "cluster_name" {
  description = "GKE cluster name"
}

variable "cluster_location" {
  description = "GKE cluster location"
  default     = "us-west1" 
}
