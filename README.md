# MERN Stack Production Setup

Full-stack MERN application with CI/CD and GCP Cloud Run deployment.

## Services
- **Frontend**: React + Vite (port 80)
- **API Gateway**: Express (port 3000)
- **Auth Service**: Express (port 4000)
- **Books Service**: Express + MongoDB (port 5000)

## GitHub Secrets Required

| Secret | Value |
|--------|-------|
| DOCKER_HUB_USERNAME | satyam2324 |
| DOCKER_HUB_TOKEN | Your Docker Hub access token |
| GCP_PROJECT_ID | hici-493107 |
| GCP_REGION | us-central1 |
| GCP_WORKLOAD_IDENTITY_PROVIDER | projects/870371007647/locations/global/workloadIdentityPools/mern-pool/providers/mern-provider |
| GCP_SERVICE_ACCOUNT | deployer@hici-493107.iam.gserviceaccount.com |
| MONGO_URI | mongodb+srv://... (optional - without it books service works in demo mode) |

## How It Works
1. Push to `main` → GitHub Actions builds all 4 Docker images
2. Images pushed to Docker Hub + GCR
3. GitHub Actions automatically deploys to Cloud Run
4. Get URLs from GitHub Actions logs

## Cloud Run Services (auto-created)
- mern-auth
- mern-books
- mern-gateway
- mern-frontend
