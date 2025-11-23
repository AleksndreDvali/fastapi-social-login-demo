terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -------------------------
# Enable required APIs
# -------------------------

resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# -------------------------
# Artifact Registry Repo
# -------------------------

resource "google_artifact_registry_repository" "app_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.service_name  # one repo per service
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}

# -------------------------
# Cloud Run runtime Service Account
# -------------------------

resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run runtime SA for ${var.service_name}"
}

# Allow runtime SA to pull from Artifact Registry
resource "google_project_iam_member" "runtime_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# -------------------------
# (Optional) output values
# -------------------------

output "artifact_registry_repo" {
  value       = google_artifact_registry_repository.app_repo.name
  description = "Full Artifact Registry repo name"
}

output "cloud_run_runtime_sa_email" {
  value       = google_service_account.cloud_run_sa.email
  description = "Service account Cloud Run should run as"
}
