variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "europe-west1"
}

variable "github_repository" {
  type        = string
  description = "GitHub repo in the form owner/repo"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}
