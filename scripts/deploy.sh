#!/bin/bash
set -e

echo "=== MERN Stack Cloud Run Deployment ==="

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <image-tag> [mongo-uri]"
    echo "Example: ./deploy.sh abc1234 mongodb+srv://user:pass@cluster.mongodb.net/db"
    exit 1
fi

IMAGE_TAG="$1"
MONGO_URI="${2:-}"
PROJECT_ID="${GCP_PROJECT_ID:-deployment-488406}"
REGION="${GCP_REGION:-us-central1}"

echo "Image tag: $IMAGE_TAG"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

echo ""
echo "=== Deploying Auth Service ==="
gcloud run deploy mern-auth \
    --image gcr.io/$PROJECT_ID/mern-auth:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --quiet

echo ""
echo "=== Deploying Books Service ==="
gcloud run deploy mern-books \
    --image gcr.io/$PROJECT_ID/mern-books:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    $([ -n "$MONGO_URI" ] && echo "--set-env-vars MONGO_URI=$MONGO_URI") \
    --quiet

echo ""
echo "=== Deploying Gateway Service ==="
gcloud run deploy mern-gateway \
    --image gcr.io/$PROJECT_ID/mern-gateway:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars AUTH_URL=https://mern-auth-$REGION.run.app,BOOKS_URL=https://mern-books-$REGION.run.app \
    --quiet

echo ""
echo "=== Deploying Frontend Service ==="
gcloud run deploy mern-frontend \
    --image gcr.io/$PROJECT_ID/mern-frontend:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --quiet

echo ""
echo "=== Deployment Complete ==="
echo "Frontend: $(gcloud run services describe mern-frontend --platform managed --region $REGION --format 'value(status.url)')"
echo "Gateway:  $(gcloud run services describe mern-gateway --platform managed --region $REGION --format 'value(status.url)')"
echo "Auth:     $(gcloud run services describe mern-auth --platform managed --region $REGION --format 'value(status.url)')"
echo "Books:    $(gcloud run services describe mern-books --platform managed --region $REGION --format 'value(status.url)')"
