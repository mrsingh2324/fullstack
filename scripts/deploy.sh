#!/bin/bash
set -e

echo "=== MERN Stack Cloud Run Deployment ==="

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <commit-sha> [mongo-uri]"
    exit 1
fi

IMAGE_TAG="$1"
MONGO_URI="${2:-}"
PROJECT_ID="${GCP_PROJECT_ID:-deployment-488406}"
REGION="${GCP_REGION:-us-central1}"
DOCKER_HUB_USER="satyam2324"

echo "Image: $DOCKER_HUB_USER, Tag: $IMAGE_TAG"

echo ""
echo "=== Pulling from Docker Hub ==="
docker pull ${DOCKER_HUB_USER}/mern-auth:$IMAGE_TAG || echo "Auth not found"
docker pull ${DOCKER_HUB_USER}/mern-books:$IMAGE_TAG || echo "Books not found"
docker pull ${DOCKER_HUB_USER}/mern-gateway:$IMAGE_TAG || echo "Gateway not found"
docker pull ${DOCKER_HUB_USER}/mern-frontend:$IMAGE_TAG || echo "Frontend not found"

echo ""
echo "=== Pushing to Artifact Registry ==="
gcloud auth configure-docker --quiet

# Create AR repo if not exists
gcloud artifacts repositories create mern-repo --repository-format=DOCKER --location=$REGION --project=$PROJECT_ID 2>/dev/null || true

docker tag ${DOCKER_HUB_USER}/mern-auth:$IMAGE_TAG ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-auth:$IMAGE_TAG
docker tag ${DOCKER_HUB_USER}/mern-books:$IMAGE_TAG ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-books:$IMAGE_TAG
docker tag ${DOCKER_HUB_USER}/mern-gateway:$IMAGE_TAG ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-gateway:$IMAGE_TAG
docker tag ${DOCKER_HUB_USER}/mern-frontend:$IMAGE_TAG ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-frontend:$IMAGE_TAG

docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-auth:$IMAGE_TAG
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-books:$IMAGE_TAG
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-gateway:$IMAGE_TAG
docker push ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-frontend:$IMAGE_TAG

echo ""
echo "=== Deploying Auth Service ==="
gcloud run deploy mern-auth \
    --image ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-auth:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deploying Books Service ==="
gcloud run deploy mern-books \
    --image ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-books:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deploying Gateway Service ==="
gcloud run deploy mern-gateway \
    --image ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-gateway:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --update-env-vars AUTH_URL=https://mern-auth-$REGION.run.app,BOOKS_URL=https://mern-books-$REGION.run.app

echo ""
echo "=== Deploying Frontend Service ==="
gcloud run deploy mern-frontend \
    --image ${REGION}-docker.pkg.dev/$PROJECT_ID/mern-repo/mern-frontend:$IMAGE_TAG \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated

echo ""
echo "=== Deployment Complete ==="
echo "Frontend: $(gcloud run services describe mern-frontend --platform managed --region $REGION --format 'value(status.url)')"
echo "Gateway:  $(gcloud run services describe mern-gateway --platform managed --region $REGION --format 'value(status.url)')"
echo "Auth:     $(gcloud run services describe mern-auth --platform managed --region $REGION --format 'value(status.url)')"
echo "Books:    $(gcloud run services describe mern-books --platform managed --region $REGION --format 'value(status.url)')"
