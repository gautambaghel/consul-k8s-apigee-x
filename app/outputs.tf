output "apigee_developer_key" {
  description = "The developer key for API requests"
  value       = random_password.consumer_key.result
  sensitive   = true
}
