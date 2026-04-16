#!/bin/bash
set -e

echo "=== MERN Stack Deployment Script ==="

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <image-tag> [mongo-uri]"
    echo "Example: ./deploy.sh v1.1.0 mongodb+srv://user:pass@cluster.mongodb.net/db"
    exit 1
fi

IMAGE_TAG="$1"
MONGO_URI="${2:-}"

echo "Image tag: $IMAGE_TAG"
echo "Project ID: $GCP_PROJECT_ID"
echo "Region: $GCP_REGION"

cd "$(dirname "$0")/../terraform"

echo "Initializing Terraform..."
terraform init

echo "Planning deployment..."
if [ -n "$MONGO_URI" ]; then
    terraform plan -var "project_id=$GCP_PROJECT_ID" -var "region=$GCP_REGION" -var "image_tag=$IMAGE_TAG" -var "mongo_uri=$MONGO_URI"
else
    terraform plan -var "project_id=$GCP_PROJECT_ID" -var "region=$GCP_REGION" -var "image_tag=$IMAGE_TAG"
fi

echo "Applying deployment..."
if [ -n "$MONGO_URI" ]; then
    terraform apply -var "project_id=$GCP_PROJECT_ID" -var "region=$GCP_REGION" -var "image_tag=$IMAGE_TAG" -var "mongo_uri=$MONGO_URI" -auto-approve
else
    terraform apply -var "project_id=$GCP_PROJECT_ID" -var "region=$GCP_REGION" -var "image_tag=$IMAGE_TAG" -auto-approve
fi

echo "Getting load balancer IP..."
terraform output load_balancer_ip

echo "=== Deployment Complete ==="
