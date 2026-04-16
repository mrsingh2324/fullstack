#!/bin/bash
set -e

echo "=== MERN Stack Cloud Run Deployment ==="

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <commit-sha> [mongo-uri]"
    echo "Example: ./deploy.sh abc1234"
    exit 1
fi

IMAGE_TAG="$1"
MONGO_URI="${2:-}"
PROJECT_ID="${GCP_PROJECT_ID:-deployment-488406}"
REGION="${GCP_REGION:-us-central1}"
DOCKER_HUB_USER="${DOCKER_HUB_USERNAME:-satyam2324}"

echo "Image tag: $IMAGE_TAG"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

echo ""
echo "=== Deploying Auth Service ==="
gcloud run deploy mern-auth \
    --image docker.io/$DOCKER_HUB_USER/mern-auth:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deploying Books Service ==="
gcloud run deploy mern-books \
    --image docker.io/$DOCKER_HUB_USER/mern-books:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deploying Gateway Service ==="
gcloud run deploy mern-gateway \
    --image docker.io/$DOCKER_HUB_USER/mern-gateway:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --update-env-vars AUTH_URL=https://mern-auth-$REGION.run.app,BOOKS_URL=https://mern-books-$REGION.run.app

echo ""
echo "=== Deploying Frontend Service ==="
gcloud run deploy mern-frontend \
    --image docker.io/$DOCKER_HUB_USER/mern-frontend:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deployment Complete ==="
echo "Frontend: $(gcloud run services describe mern-frontend --platform managed --region $REGION --format 'value(status.url)')"
echo "Gateway:  $(gcloud run services describe mern-gateway --platform managed --region $REGION --format 'value(status.url)')"
echo "Auth:     $(gcloud run services describe mern-auth --platform managed --region $REGION --format 'value(status.url)')"
echo "Books:    $(gcloud run services describe mern-books --platform managed --region $REGION --format 'value(status.url)')"
