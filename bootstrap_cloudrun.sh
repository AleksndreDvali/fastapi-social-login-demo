#!/usr/bin/env bash
set -euo pipefail

########################################
# CONFIG – change if needed
########################################
PROJECT_ID="wialon-ab12"
REGION="europe-west1"
SERVICE_NAME="fastapi-social-login"
REPO_NAME="fastapi-social-login"      # Artifact Registry repo id
RUNTIME_SA_NAME="cloud-run-sa"        # Cloud Run runtime service account id

########################################
# Derived values
########################################
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"
RUNTIME_SA_EMAIL="${RUNTIME_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ">>> Using project:        ${PROJECT_ID}"
echo ">>> Region:               ${REGION}"
echo ">>> Service name:         ${SERVICE_NAME}"
echo ">>> Artifact repo:        ${REPO_NAME}"
echo ">>> Image:                ${IMAGE}"
echo ">>> Runtime SA email:     ${RUNTIME_SA_EMAIL}"
echo

########################################
# 1. Set gcloud project
########################################
echo ">>> Setting gcloud project..."
gcloud config set project "${PROJECT_ID}"

########################################
# 2. Enable required APIs
########################################
echo ">>> Enabling required APIs (may take a few minutes, safe if already enabled)..."
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  cloudbuild.googleapis.com

########################################
# 3. Create Artifact Registry repo (if not exists)
########################################
echo ">>> Creating Artifact Registry repo (if not exists)..."
gcloud artifacts repositories describe "${REPO_NAME}" \
  --location="${REGION}" >/dev/null 2>&1 || \
gcloud artifacts repositories create "${REPO_NAME}" \
  --repository-format=docker \
  --location="${REGION}" \
  --description="Images for ${SERVICE_NAME}"

########################################
# 4. Create Cloud Run runtime service account (if not exists)
########################################
echo ">>> Creating Cloud Run runtime service account (if not exists)..."
gcloud iam service-accounts describe "${RUNTIME_SA_EMAIL}" >/dev/null 2>&1 || \
gcloud iam service-accounts create "${RUNTIME_SA_NAME}" \
  --display-name="Cloud Run Runtime SA"

########################################
# 5. Grant Artifact Registry reader role to runtime SA
########################################
echo ">>> Granting Artifact Registry reader role to runtime SA..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${RUNTIME_SA_EMAIL}" \
  --role="roles/artifactregistry.reader" \
  --quiet

########################################
# 6. Build & push image with Cloud Build
########################################
echo ">>> Building and pushing container image with Cloud Build..."
# Assumes Dockerfile is in current directory (repo root)
gcloud builds submit \
  --tag "${IMAGE}" \
  .

########################################
# 7. Deploy to Cloud Run
########################################
echo ">>> Deploying service to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --service-account "${RUNTIME_SA_EMAIL}" \
  --allow-unauthenticated \
  --port 8000

########################################
# 8. Show service URL
########################################
echo
echo ">>> Deployment complete!"
echo ">>> Cloud Run service URL:"
gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --format="value(status.url)"
echo
