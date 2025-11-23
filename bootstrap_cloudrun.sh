#!/usr/bin/env bash

gcloud config set project wialon-ab12

# Create github-deployer SA
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub CI/CD deployer"


# Give it ability to:

# * deploy Cloud Run

# * build images (Cloud Build) or push directly to Artifact Registry

# * act as the runtime SA

SA="github-deployer@wialon-ab12.iam.gserviceaccount.com"
PROJECT_ID="wialon-ab12"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/iam.serviceAccountUser"


# Create a JSON key and store in GitHub

gcloud iam service-accounts keys create github-deployer-key.json \
  --iam-account="$SA"
