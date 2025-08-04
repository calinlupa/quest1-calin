# Defines a Google Cloud Run v2 service.
# This resource manages the deployment and configuration of a serverless container.
resource "google_cloud_run_v2_service" "default" {
  name     = var.service_name
  location = var.location
  # Deletion protection is disabled for easier cleanup in non-production environments.
  # For production, this should be set to true.
  deletion_protection = false

  # The template defines the configuration for new revisions of the service.
  template {
    # Defines the autoscaling parameters for the service.
    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    # Defines the container to be run in the service.
    containers {
      image = var.image
      name = "rearc-quest-container"

      # Defines the CPU and memory resource limits for the container.
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      # Specifies the port the container listens on for incoming requests.
      ports {
        container_port = var.container_port
      }

      # Sets environment variables for the container.
      # Here, it's used to inject the secret word.
      env {
        name  = "SECRET_WORD"
        value = var.secret_word
      }
    }
  }
}

# Grants public access to the Cloud Run service, for direct access to a reginal deployment
resource "google_cloud_run_v2_service_iam_binding" "default" {
  name     = google_cloud_run_v2_service.default.name
  location = google_cloud_run_v2_service.default.location
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

# --- Module Outputs ---

# Outputs the name of the created Cloud Run service.
# Marked as sensitive to avoid showing it in logs, although the name itself is not a secret.
output "service_name" {
  value       = google_cloud_run_v2_service.default.name
  description = "The name of the Cloud Run service."
  sensitive   = true
}

# Outputs the publicly accessible URL of the Cloud Run service.
output "service_url" {
  value       = google_cloud_run_v2_service.default.uri
  description = "The URL of the Cloud Run service."
}