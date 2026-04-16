# MERN Stack Production Setup

Full-stack MERN application with CI/CD and GCP deployment.

## Services
- **Frontend**: React + Vite (port 80)
- **API Gateway**: Express (port 3000)
- **Auth Service**: Express (port 4000)
- **Books Service**: Express + MongoDB (port 5000)

## GitHub Secrets Required

| Secret | Value |
|--------|-------|
| DOCKER_HUB_USERNAME | Your Docker Hub username |
| DOCKER_HUB_TOKEN | Docker Hub access token |
| GCP_PROJECT_ID | hici-493107 |
| GCP_WORKLOAD_IDENTITY_PROVIDER | `projects/870371007647/locations/global/workloadIdentityPools/mern-pool/providers/mern-provider` |
| GCP_SERVICE_ACCOUNT | `deployer@hici-493107.iam.gserviceaccount.com` |

## Setup Workload Identity (run locally)

```bash
# Enable APIs
gcloud services enable compute.googleapis.com container.googleapis.com artifactregistry.googleapis.com

# Create Workload Identity Pool
gcloud iam workload-identity-pools create mern-pool \
  --location="global" \
  --project=hici-493107

# Create GitHub provider (replace YOUR_GITHUB_ORG with your org/username)
gcloud iam workload-identity-pools providers create-github mern-provider \
  --location="global" \
  --project=hici-493107 \
  --owner="YOUR_GITHUB_ORG" \
  --repository="mern-prod-microservices"

# Allow GitHub to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  deployer@hici-493107.iam.gserviceaccount.com \
  --member="principalSet://iam.googleapis.com/projects/870371007647/locations/global/workloadIdentityPools/mern-pool/attribute.repository/mern-prod-microservices" \
  --role="roles/iam.workloadIdentityUser"
```

## Deploy

```bash
export GCP_PROJECT_ID="hici-493107"
export GCP_REGION="us-central1"

./scripts/deploy.sh $GITHUB_SHA "mongodb+srv://..."
```

## How It Works
1. Push to `main` → GitHub Actions builds all 4 Docker images
2. Images pushed to Docker Hub + GCR
3. Run deploy script to provision GCP MIG + Load Balancer
