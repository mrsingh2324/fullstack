
# MERN Microservices (Production Starter)

## 1. Prerequisites
- gcloud CLI
- kubectl
- terraform
- docker

## 2. Setup GCP
gcloud auth login
gcloud config set project YOUR_PROJECT

## 3. Terraform (GKE)
cd terraform
terraform init
terraform apply -var="project_id=YOUR_PROJECT"

## 4. Get credentials
gcloud container clusters get-credentials mern-cluster --region us-central1

## 5. Build & push images
gcloud auth configure-docker
docker build -t gcr.io/YOUR_PROJECT/auth ./services/auth
docker push gcr.io/YOUR_PROJECT/auth

(repeat for all services)

## 6. Update PROJECT_ID in k8s yaml

## 7. Deploy
kubectl apply -f k8s/all.yaml

## 8. Mongo Atlas
- Create cluster
- Put connection string in k8s secret:
  kubectl create secret generic mongo-secret --from-literal=uri="YOUR_URI" -n mern

## Done 🎉
