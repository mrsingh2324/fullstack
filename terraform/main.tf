terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

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
  sensitive   = true
}

locals {
  prefix = "mern"
  tags   = ["mern-app"]
}

resource "google_compute_network" "vpc" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${local.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/24"
}

resource "google_compute_firewall" "allow-http" {
  name    = "${local.prefix}-allow-http"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = local.tags
}

resource "google_compute_firewall" "allow-health-check" {
  name    = "${local.prefix}-allow-health-check"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "3000", "4000", "5000"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = local.tags
}

resource "google_compute_instance_template" "auth_template" {
  name         = "${local.prefix}-auth-template"
  machine_type = "e2-medium"
  tags         = local.tags

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.name
  }

  metadata = {
    docker-image = "gcr.io/${var.project_id}/mern-auth:${var.image_tag}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    docker pull gcr.io/${var.project_id}/mern-auth:${var.image_tag}
    docker run -d --name auth -p 4000:4000 gcr.io/${var.project_id}/mern-auth:${var.image_tag}
  EOT
}

resource "google_compute_instance_template" "books_template" {
  name         = "${local.prefix}-books-template"
  machine_type = "e2-medium"
  tags         = local.tags

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.name
  }

  metadata = {
    docker-image = "gcr.io/${var.project_id}/mern-books:${var.image_tag}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    docker pull gcr.io/${var.project_id}/mern-books:${var.image_tag}
    docker run -d --name books -p 5000:5000 -e MONGO_URI=${var.mongo_uri} gcr.io/${var.project_id}/mern-books:${var.image_tag}
  EOT
}

resource "google_compute_instance_template" "gateway_template" {
  name         = "${local.prefix}-gateway-template"
  machine_type = "e2-medium"
  tags         = local.tags

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.name
  }

  metadata = {
    docker-image = "gcr.io/${var.project_id}/mern-gateway:${var.image_tag}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    docker pull gcr.io/${var.project_id}/mern-gateway:${var.image_tag}
    docker run -d --name gateway -p 3000:3000 -e AUTH_URL=http://auth:4000 -e BOOKS_URL=http://books:5000 gcr.io/${var.project_id}/mern-gateway:${var.image_tag}
  EOT
}

resource "google_compute_instance_template" "frontend_template" {
  name         = "${local.prefix}-frontend-template"
  machine_type = "e2-medium"
  tags         = local.tags

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.name
  }

  metadata = {
    docker-image = "gcr.io/${var.project_id}/mern-frontend:${var.image_tag}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    docker pull gcr.io/${var.project_id}/mern-frontend:${var.image_tag}
    docker run -d --name frontend -p 80:80 gcr.io/${var.project_id}/mern-frontend:${var.image_tag}
  EOT
}

resource "google_compute_region_instance_group_manager" "auth_mig" {
  name               = "${local.prefix}-auth-mig"
  region             = var.region
  base_instance_name = "auth"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.auth_template.id
  }
}

resource "google_compute_region_instance_group_manager" "books_mig" {
  name               = "${local.prefix}-books-mig"
  region             = var.region
  base_instance_name = "books"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.books_template.id
  }
}

resource "google_compute_region_instance_group_manager" "gateway_mig" {
  name               = "${local.prefix}-gateway-mig"
  region             = var.region
  base_instance_name = "gateway"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.gateway_template.id
  }
}

resource "google_compute_region_instance_group_manager" "frontend_mig" {
  name               = "${local.prefix}-frontend-mig"
  region             = var.region
  base_instance_name = "frontend"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.frontend_template.id
  }
}

resource "google_compute_health_check" "http_health_check" {
  name = "${local.prefix}-health-check"
  http_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "frontend_backend" {
  name          = "${local.prefix}-frontend-backend"
  protocol      = "HTTP"
  port_name     = "http"
  health_checks = [google_compute_health_check.http_health_check.id]

  backend {
    group                 = google_compute_region_instance_group_manager.frontend_mig.id
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${local.prefix}-url-map"
  default_service = google_compute_backend_service.frontend_backend.id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${local.prefix}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "${local.prefix}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.http_forwarding_rule.ip_address
}
