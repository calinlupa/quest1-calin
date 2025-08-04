# Terraform block to define required provider versions and other settings.
terraform {
  required_providers {
    # Specifies the required version for the Google Provider.
    google = {
      source  = "hashicorp/google"
      version = "~> 6.46.0"
    }
  }
}

# Configures the Google Cloud provider with the project ID and a default region.
# The region is used for resources that are not explicitly assigned a location.
provider "google" {
  project = var.project_id
  region  = "us-central1" # Default region for provider-level operations.
}

# Data source to fetch the latest version of the "SECRET_WORD" from Google Secret Manager.
# This allows the secret value to be managed outside of Terraform code.
data "google_secret_manager_secret_version" "secret_word" {
  secret  = "SECRET_WORD"
  project = var.project_id
}

# Instantiates the Cloud Run module for each region defined in the `deployment_regions` variable.
# The `for_each` loop creates a separate Cloud Run service in each specified location.
module "cloud_run_service" {
  for_each     = var.deployment_regions
  depends_on   = [data.google_secret_manager_secret_version.secret_word]
  source       = "./modules/cloud_run"
  service_name = each.value
  location     = each.key
  image        = "us-central1-docker.pkg.dev/calin-rearc/rearc-quest/rearc-quest-submission:latest"                # Assuming same image for both regions
  # Passes the fetched secret to the module, appending the region for easy identification in the app.
  secret_word  = "${data.google_secret_manager_secret_version.secret_word.secret_data} - (running in ${each.key})" # Append to the secret word the deployemnt region to differentiate between deployments
}

# Data source to get the configuration of the client (e.g., user, service account) running Terraform.
data "google_client_config" "default" {}

resource "google_compute_global_address" "default" {
  name = "rearc-quest-glb-ip"
}

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  # Creates a Serverless Network Endpoint Group (NEG) for each Cloud Run service.
  # NEGs allow the Global Load Balancer to route traffic to serverless backends like Cloud Run.
  for_each              = var.deployment_regions
  name                  = "rearc-quest-cloud-run-neg-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = each.key
  cloud_run {
    service = module.cloud_run_service[each.key].service_name
  }
}

# Defines the backend service for the Global Load Balancer.
# It groups the Serverless NEGs and defines traffic settings.
resource "google_compute_backend_service" "cloud_run_backend_global" {
  name                  = "rearc-quest-cloud-run-backend-global"
  protocol              = "HTTPS"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED" # For global external HTTP(S) load balancers

  # Dynamically adds each of the created NEGs as a backend for this service.
  # This allows the load balancer to distribute traffic across all regions.
  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.cloud_run_neg
    content {
      group = backend.value.id
    }
  }

}

# Creates a URL map to route all incoming requests to the default backend service.
resource "google_compute_url_map" "default" {
  name = "rearc-quest-url-map"
  # The global load balancer will automatically route requests to the closest healthy backend based on user proximity.
  default_service = google_compute_backend_service.cloud_run_backend_global.id
}



# Creates a target proxy to handle incoming HTTP traffic and forward it to the URL map.
resource "google_compute_target_http_proxy" "default" {
  name    = "rearc-quest-http-proxy"
  url_map = google_compute_url_map.default.id
}

# --- SSL Certificate Management using Secret Manager ---

# Creates a secret in Secret Manager to store the SSL certificate.
resource "google_secret_manager_secret" "ssl_certificate" {
  secret_id = "ssl-certificate"
  replication {
    auto {}
  }
}
# Adds a version to the secret with the content of the local certificate file.
resource "google_secret_manager_secret_version" "ssl_certificate" {
  secret      = google_secret_manager_secret.ssl_certificate.id
  secret_data = file("./local.dev.pem")
}

# Creates a secret in Secret Manager to store the SSL private key.
resource "google_secret_manager_secret" "ssl_private_key" {
  secret_id = "ssl-private-key"
  replication {
    auto {}
  }
}
# Adds a version to the secret with the content of the local private key file.
resource "google_secret_manager_secret_version" "ssl_private_key" {
  secret      = google_secret_manager_secret.ssl_private_key.id
  secret_data = file("./local.dev-key.pem")
}

# Creates a Google-managed SSL certificate resource for the load balancer.
# It reads the certificate and private key data directly from Secret Manager.
resource "google_compute_ssl_certificate" "default" {
  name        = "rearc-quest-ssl-certificate"
  private_key = google_secret_manager_secret_version.ssl_private_key.secret_data
  certificate = google_secret_manager_secret_version.ssl_certificate.secret_data
}

# Creates a target proxy to handle incoming HTTPS traffic.
# It uses the SSL certificate to terminate TLS and forwards traffic to the URL map.
resource "google_compute_target_https_proxy" "default" {
  name             = "rearc-quest-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_ssl_certificate.default.id]
}

# --- Global Forwarding Rules ---

# Creates a forwarding rule to direct HTTPS traffic (port 443) from the global IP to the HTTPS proxy.
resource "google_compute_global_forwarding_rule" "https_default" {
  name                  = "rearc-quest-https-forwarding-rule"
  ip_address            = google_compute_global_address.default.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Creates a forwarding rule to direct HTTP traffic (port 80) from the global IP to the HTTP proxy.
# This is often used to redirect HTTP to HTTPS.
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "rearc-quest-http-forwarding-rule"
  ip_address            = google_compute_global_address.default.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  load_balancing_scheme = "EXTERNAL"
}

# --- Outputs ---

# Outputs the URLs of the individual Cloud Run services for direct access during testing.
output "cloud_run_service_url" {
  value       = { for k, v in module.cloud_run_service : k => v.service_url }
  description = "The URLs of the deployed Cloud Run services per region."
}

# Outputs the public IP address of the Global Load Balancer.
output "glb_ip_address" {
  value       = google_compute_global_address.default.address
  description = "The IP address of the Global Load Balancer."
}
