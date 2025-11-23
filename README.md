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

## 📂 Project Structure

```
project/
│── app/
│   ├── main.py
│   ├── auth/
│   ├── models/
│   ├── routes/
│   ├── templates/
│   └── static/
│── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│── requirements.txt
│── README.md
│── .gitignore
```

---

## ☁️ Deployment (Terraform + GCP)
This project includes a complete infrastructure-as-code setup using **Terraform** to provision and manage resources on **Google Cloud Platform**.

Infrastructure may include:
- Virtual machines or Cloud Run service
- Firestore (Native Mode) database
- GCP Load Balancer
- Private VPC networking
- GCP IAM roles
- Secrets Manager for OAuth credentials
- Service Account with impersonation enabled (no service-account.json required)

To deploy:

```bash
cd infra
tf init
tf plan
tf apply
```

Make sure you configure:
- `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` if using impersonation
- `GOOGLE_APPLICATION_CREDENTIALS`
- Your GCP project ID
- Terraform backend config (optional)

---

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

