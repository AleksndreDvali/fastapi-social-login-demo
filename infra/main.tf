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
# Project info (used for WIF member strings)
# -------------------------

data "google_project" "project" {}

# -------------------------
# GitHub deployer service account
# -------------------------

resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Deployer SA"
}

# -------------------------
# Workload Identity Federation for GitHub
# -------------------------

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "OIDC pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  # Map GitHub OIDC token fields into attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Restrict this provider to your specific GitHub repo
  # Make sure var.github_repository = "AleksndreDvali/fastapi-social-login-demo"
  attribute_condition = "assertion.repository=='${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub identities from this pool to impersonate the github_deployer SA
resource "google_service_account_iam_member" "github_deployer_wif" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}

# -------------------------
# IAM roles for GitHub deployer SA
# -------------------------
# These are the roles used by your CI to:
# - build & push images
# - deploy to Cloud Run
# - act as other service accounts (runtime SA, etc.)

resource "google_project_iam_member" "deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# If you decide to use Cloud Build in CI (gcloud builds submit)
resource "google_project_iam_member" "deployer_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# NOTE: we no longer manage google_project_service, Artifact Registry repo,
# Cloud Run service, or the runtime SA here – those are created by bootstrap_cloudrun.sh
# and then updated by gcloud run deploy from GitHub Actions.

# -------------------------
# (Optional) Read existing Cloud Run service for URL output
# -------------------------

data "google_cloud_run_v2_service" "fastapi_social_login" {
  name     = var.service_name   # e.g. "fastapi-social-login"
  location = var.region
}

# -------------------------
# Outputs
# -------------------------

output "cloud_run_url" {
  value       = data.google_cloud_run_v2_service.fastapi_social_login.uri
  description = "Existing Cloud Run service URL"
}

output "github_workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Use this in GitHub secret GCP_WORKLOAD_IDENTITY_PROVIDER"
}
