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

# Create the Artifact Registry repo
gcloud artifacts repositories create fastapi-social-login \
  --repository-format=docker \
  --location=europe-west1 \
  --description="Images for fastapi-social-login"

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