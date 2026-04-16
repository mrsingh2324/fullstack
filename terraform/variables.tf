variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "mongo_uri" {
  description = "MongoDB connection URI"
  type        = string
  default     = ""
  sensitive   = true
}
