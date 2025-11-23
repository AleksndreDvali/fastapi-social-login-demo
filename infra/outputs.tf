output "cloud_run_url" {
  value       = google_cloud_run_v2_service.fastapi_social_login.uri
  description = "Deployed Cloud Run URL"
}

output "github_workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Use this in GitHub secret GCP_WORKLOAD_IDENTITY_PROVIDER"
}