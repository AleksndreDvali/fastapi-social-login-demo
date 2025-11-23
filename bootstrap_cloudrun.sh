#!/usr/bin/env bash

# Define your project ID once
PROJECT_ID="wialon-ab34"

# Set the project in gcloud config
gcloud config set project "$PROJECT_ID"

# Create GitHub-deployer service account
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub CI/CD deployer"



# (Optional) Print out what you're about to do
echo "Service account to use: $SA"

# Enable IAM API
gcloud services enable iam.googleapis.com --project=$PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com --project=$PROJECT_ID


# Give it ability to:

# * deploy Cloud Run

# * build images (Cloud Build) or push directly to Artifact Registry

# * act as the runtime SA

# Construct the service account email using PROJECT_ID
SA="github-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

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

# # Create the Artifact Registry repo
# gcloud artifacts repositories create fastapi-social-login \
#   --repository-format=docker \
#   --location=europe-west1 \
#   --description="Images for fastapi-social-login"

# Create a JSON key and store in GitHub

gcloud iam service-accounts keys create github-deployer-key.json \
  --iam-account="$SA"


# Directory to put the file
dir=".vscode"

# Check if the directory exists, if not — create it
if [ ! -d "$dir" ]; then
  mkdir -p "$dir"
fi

# Now write the JSON into .vscode/launch.json
cat <<EOF > "$dir/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "FastAPI (Uvicorn)",
            "type": "debugpy",
            "request": "launch",
            "module": "uvicorn",
            "args": [
                "app.main:app",
                "--host", "0.0.0.0",
                "--port", "8080",
                "--reload"
            ],
            "jinja": true,
            "console": "integratedTerminal",
            "env": {
                "VAR": "value",
            }
        }
    ]
}
EOF