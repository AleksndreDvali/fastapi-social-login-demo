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

resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# -------------------------
# Artifact Registry
# -------------------------

resource "google_artifact_registry_repository" "fastapi_social_login_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.service_name  # <– repo name
  description   = "Images for ${var.service_name}"
  format        = "DOCKER"


  depends_on = [
    google_project_service.artifactregistry
  ]
}

# -------------------------
# Service Accounts
# -------------------------

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Runtime SA"
}

resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Deployer SA"
}

# Allow Cloud Run SA to read images from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "cloud_run_reader" {
  location   = google_artifact_registry_repository.fastapi_social_login_repo.location
  repository = google_artifact_registry_repository.fastapi_social_login_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# -------------------------
# Workload Identity Federation for GitHub
# -------------------------

data "google_project" "project" {}

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "OIDC pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # 🔐 Allow only your repo to use this provider
  # (owner/repo must match your GitHub repo exactly)
  attribute_condition = "assertion.repository=='AleksndreDvali/fastapi-social-login-demo'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}


# Allow GitHub identities (for this specific repo) to impersonate github_deployer SA
resource "google_service_account_iam_member" "github_deployer_wif" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}

# -------------------------
# IAM for deployer SA
# -------------------------

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

# Allow GitHub deployer to read / manage project services (APIs)
resource "google_project_iam_member" "deployer_serviceusage_admin" {
  project = var.project_id
  role = "roles/serviceusage.serviceUsageViewer"  # can also use  "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# -------------------------
# Cloud Run Service
# -------------------------

# Image that GitHub Actions will build & push
locals {
  fastapi_social_login_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.fastapi_social_login_repo.repository_id}/${var.service_name}:latest"
}


resource "google_cloud_run_v2_service" "fastapi_social_login" {
  name     = var.service_name   # service name
  location = var.region

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = local.fastapi_social_login_image

      ports {
        container_port = 8000
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Allow public (unauthenticated) access
resource "google_cloud_run_v2_service_iam_member" "fastapi_social_login_public" {
  name   = "projects/${var.project_id}/locations/${var.region}/services/${google_cloud_run_v2_service.fastapi_social_login.name}"
  role   = "roles/run.invoker"
  member = "allUsers"
}
