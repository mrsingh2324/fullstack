#!/bin/bash
# Setup Workload Identity for GitHub Actions

PROJECT_ID="hici-493107"
POOL_NAME="mern-pool"
PROVIDER_NAME="mern-provider"
SA_EMAIL="deployer@${PROJECT_ID}.iam.gserviceaccount.com"

echo "=== Setting up Workload Identity ==="

# Enable required APIs
echo "Enabling APIs..."
gcloud services enable compute.googleapis.com artifactregistry.googleapis.com --project=$PROJECT_ID

# Create Workload Identity Pool
echo "Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create $POOL_NAME \
  --location="global" \
  --project=$PROJECT_ID 2>/dev/null || echo "Pool may already exist"

# Create GitHub provider (for repo: satyam2324/mern-prod-microservices)
echo "Creating GitHub provider..."
gcloud iam workload-identity-pools providers create-github $PROVIDER_NAME \
  --location="global" \
  --project=$PROJECT_ID \
  --owner="satyam2324" \
  --repository="mern-prod-microservices" 2>/dev/null || echo "Provider may already exist"

# Get the Workload Identity Provider resource
POOL_ID=$(gcloud iam workload-identity-pools describe $POOL_NAME \
  --location="global" \
  --project=$PROJECT_ID --format="get(name)")

echo "Workload Identity Pool: $POOL_ID"

# Allow GitHub to impersonate service account
echo "Adding IAM policy..."
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/satyam2324/mern-prod-microservices" \
  --role="roles/iam.workloadIdentityUser" 2>/dev/null || echo "Policy may already exist"

# Output the provider name for GitHub secrets
PROVIDER_FULL_NAME="${POOL_ID}/providers/${PROVIDER_NAME}"
echo ""
echo "=== Add these to GitHub Secrets ==="
echo "GCP_WORKLOAD_IDENTITY_PROVIDER: $PROVIDER_FULL_NAME"
echo "GCP_SERVICE_ACCOUNT: $SA_EMAIL"
echo "GCP_PROJECT_ID: $PROJECT_ID"
echo ""
echo "Done!"
