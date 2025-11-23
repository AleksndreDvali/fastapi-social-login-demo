# FastAPI + HTMX User Management

A modern user management and authentication system built with **FastAPI** (backend) and **HTMX** (frontend).  
Features include:

- ✅ User registration  
- ✅ Email/password login  
- ✅ Login with **Google OAuth**  
- ✅ Login with **Facebook OAuth**  
- ✅ Session-based authentication  
- ✅ Simple, dynamic HTMX-driven UI
- ✅ **Infrastructure deployed using Terraform on Google Cloud Platform (GCP)**

This project is designed as a portfolio-friendly example of building a full-stack authentication system using lightweight and modern tools.

---

## 🚀 Tech Stack

### **Backend**
- FastAPI
- Python 3.10+
- OAuth (Google + Facebook)
- Firestore (Native Mode)
- Jinja2 templates

### **Frontend**
- HTMX
- TailwindCSS (optional)
- Minimal JS

### **Infrastructure**
- Terraform (IaC)
- Google Cloud Platform (GCP)
- GCE / Cloud Run / Cloud SQL (depending on architecture)
- GCP IAM, VPC, Secrets Manager

---


## ☁️ Deployment (Terraform + bootstrap_cloudrun.sh)


## Prerequisites

Before you begin, make sure you have:

- A GCP project to deploy to (you must have permissions to enable APIs, create service accounts, assign IAM roles).  
- The Google Cloud SDK (`gcloud`) installed and authenticated.  
- Terraform CLI installed (version compatible with your code).  
- Git (to clone the repo).  
- (Optional) Docker or Container Registry access if you're building and pushing images.  
- (Optional) VS Code for local debugging (since `launch.json` is prepared for that).

---

## Configuration

1. Clone the repository:  
   ```bash
   git clone <your‑repo‑url>
   cd <repo‑root>
   ```

2. In `infra/terraform.tfvars.sample`, examine the sample values:
   ```hcl
   project_id   = "social‑login"
   region       = "europe‑west1"
   service_name = "fastapi‑social‑login"
   ```
   Copy this file to `terraform.tfvars` (in the same `infra/` dir) and update with your actual values (especially `project_id`).  
   ```bash
   cp infra/terraform.tfvars.sample infra/terraform.tfvars
   # edit infra/terraform.tfvars and set project_id to your actual project
   ```

---

## Bootstrap Setup

This step will prepare your GCP project: set the project, create a deployer service account, enable required APIs, assign IAM roles, and create a key.

Run the script:

```bash
chmod +x scripts/bootstrap_cloudrun.sh
./scripts/bootstrap_cloudrun.sh
```

**What the script does:**

- Sets the active GCP project via `gcloud config set project "$PROJECT_ID"`.  
- Creates a service account named `github‑deployer`.  
- Enables the IAM API (`iam.googleapis.com`) and Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`) for the project.  
- Assigns IAM roles to the deployer service account: `roles/run.admin`, `roles/artifactregistry.writer`, `roles/cloudbuild.builds.editor`, `roles/iam.serviceAccountUser`.  
- Creates a JSON key file `github‑deployer-key.json` for the service account.  
- Creates or ensures `.vscode/launch.json` exists (for debugging configuration).

**Important:** Make sure you update `PROJECT_ID` inside the script (or parameterize it) before running if you’re using a different project.

---

## Terraform Workflow

Once the bootstrap is done and your `terraform.tfvars` is set:

1. Navigate to the infra directory:  
   ```bash
   cd infra/
   ```

2. Initialize Terraform:  
   ```bash
   terraform init
   ```

3. Optionally format & validate:  
   ```bash
   terraform fmt
   terraform validate
   ```

4. Create a plan:  
   ```bash
   terraform plan -out=tfplan
   ```

5. Review the plan, then apply:  
   ```bash
   terraform apply tfplan
   ```

6. After apply, you can inspect outputs:  
   ```bash
   terraform output
   ```

These outputs may include identifiers for the Cloud Run service, service account email, endpoint URLs, etc.

---

## Deployment Workflow

With the infrastructure live, you can move to application deployment. Assuming you are using CI/CD (e.g., GitHub Actions) with the service account created in the bootstrap step:

1. Build your container image (e.g., using Cloud Build or locally + push to Artifact Registry).  
2. Deploy to Cloud Run (or whichever runtime defined). Use the `service_name`, `region`, and other variables from Terraform.  
3. In your CI workflow, specify or mount the `github‑deployer-key.json` as credentials for deployment.

For local development/debugging (courtesy of `.vscode/launch.json`):

- Open VS Code  
- Use the “FastAPI (Uvicorn)” debug configuration  
- Ensure your environment variables are set (or update `launch.json` accordingly)  
- Run/debug your app locally  

---

## Environment & Variables

- `PROJECT_ID`: your GCP project identifier (set in both `bootstrap_cloudrun.sh` and `terraform.tfvars`).  
- `region`: GCP region for deployment (e.g., `europe‑west1`).  
- `service_name`: name of the Cloud Run or similar service (e.g., `fastapi‑social‑login`).  
- After bootstrap: `github‑deployer-key.json` is the service account JSON key — handle it securely (e.g., GitHub Secrets).  
- The `.vscode/launch.json` is auto‑generated and may contain placeholders (`"VAR": "value"`). Update those env vars for local debugging as required.

---

## GitHub Actions & Repository Secrets

To enable deployment from GitHub Actions, set the following **secrets** in your GitHub repository:

| Secret Name         | Description |
|---|---|
| `GCP_PROJECT_ID`     | Your Google Cloud project ID where resources are deployed. |
| `GCP_REGION`         | The GCP region (e.g. `europe‑west1`) for your Cloud Run / Terraform. |
| `GCP_SERVICE_NAME`   | The name of the Cloud Run service (or Terraform service name). |
| `GCP_SA_KEY`         | The JSON key of the GCP service account (created via your bootstrap script). |

### How to Add Secrets in GitHub:

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**.  
2. Click **New repository secret**.  
3. For each secret:
   - Set **Name** = `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_SERVICE_NAME`, or `GCP_SA_KEY`.  
   - For `GCP_SA_KEY`: paste the entire JSON key content.  
   - Click **Add secret**.

## ▶️ Running Locally

### **1. Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
```

### **2. Install dependencies**
```bash
pip install -r requirements.txt
```

### **3. Set environment variables**
Create a `.env` file:
```
GOOGLE_CLIENT_ID=your-id
GOOGLE_CLIENT_SECRET=your-secret

FACEBOOK_CLIENT_ID=your-id
FACEBOOK_CLIENT_SECRET=your-secret

SECRET_KEY=your-random-secret-key
FIRESTORE_PROJECT_ID=your-gcp-project-id
FIRESTORE_IMPERSONATE_SERVICE_ACCOUNT=service-account-name@your-gcp-project-id.iam.gserviceaccount.com
```

### **4. Run server**
```bash
uvicorn app.main:app --reload
```

---

## 🌐 OAuth Setup
You need to create OAuth apps in:

- Google Cloud Console  
- Facebook Developer Console

Add redirect URL:
```
http://localhost:8000/auth/callback/google
http://localhost:8000/auth/callback/facebook
```

---

## 📸 Screenshots
*(Add UI screenshots here after building the pages.)*

---

## 📜 License
MIT License.

---

## ⭐ Contribute
Feel free to fork the project, open issues, or submit pull requests!

