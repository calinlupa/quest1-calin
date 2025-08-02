terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    
  }
}

provider "google" {
  # Your GCP project ID
  project = var.project_id
  # Your GCP region
  region = "us-central1"
}

data "google_secret_manager_secret_version" "secret_word" {
  secret  = "SECRET_WORD"
  project = var.project_id
}

module "cloud_run_service" {
  for_each       = var.deployment_regions
  depends_on     = [data.google_secret_manager_secret_version.secret_word]
  source         = "./modules/cloud_run"
  service_name   = each.value
  location       = each.key
  image          = "us-central1-docker.pkg.dev/calin-rearc/rearc-quest/rearc-quest-submission:latest" # Assuming same image for both regions
  # append to the secret word the deployemnt region to differentiate between deployments
  secret_word    = "${data.google_secret_manager_secret_version.secret_word.secret_data}-${each.key}"
}

data "google_client_config" "default" {}


resource "google_compute_global_address" "default" {
  name = "rearc-quest-glb-ip"
}



resource "google_compute_region_network_endpoint_group" "cloud_run_neg_us" {
  name                  = "rearc-quest-cloud-run-neg-us"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = module.cloud_run_service["us-central1"].service_name
  }
}

resource "google_compute_backend_service" "cloud_run_backend_us" {
  name        = "rearc-quest-cloud-run-backend-us"
  protocol    = "HTTPS"
  port_name   = "http"
  

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg_us.id
  }
}

resource "google_compute_region_network_endpoint_group" "cloud_run_neg_eu" {
  name                  = "rearc-quest-cloud-run-neg-eu"
  network_endpoint_type = "SERVERLESS"
  region                = "europe-west1"
  cloud_run {
    service = module.cloud_run_service["europe-west1"].service_name
  }
}

resource "google_compute_backend_service" "cloud_run_backend_eu" {
  name        = "rearc-quest-cloud-run-backend-eu"
  protocol    = "HTTPS"
  port_name   = "http"
  

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg_eu.id
  }
}

resource "google_compute_url_map" "default" {
  name            = "rearc-quest-url-map"
  # The global load balancer will automatically route requests to the closest healthy backend based on user proximity.
  default_service = google_compute_backend_service.cloud_run_backend_us.id
}



resource "google_compute_target_http_proxy" "default" {
  name    = "rearc-quest-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "rearc-quest-http-forwarding-rule"
  ip_address = google_compute_global_address.default.id
  port_range = "80"
  target     = google_compute_target_http_proxy.default.id
  load_balancing_scheme = "EXTERNAL"
}

output "cloud_run_service_url" {
  value       = { for k, v in module.cloud_run_service : k => v.service_url }
  description = "The URLs of the deployed Cloud Run services per region."
}

output "glb_ip_address" {
  value       = google_compute_global_address.default.address
  description = "The IP address of the Global Load Balancer."
}

