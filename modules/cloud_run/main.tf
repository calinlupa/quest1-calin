resource "google_cloud_run_v2_service" "default" {
  name                = var.service_name
  location            = var.location
  deletion_protection = false

  template {
    containers {
      image = var.image
      ports {
        container_port = var.container_port
      }
      env {
        name  = "SECRET_WORD"
        value = var.secret_word
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_binding" "default" {
  name     = google_cloud_run_v2_service.default.name
  location = google_cloud_run_v2_service.default.location
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

output "service_name" {
  value       = google_cloud_run_v2_service.default.name
  description = "The name of the Cloud Run service."
}

output "service_url" {
  value       = google_cloud_run_v2_service.default.uri
  description = "The URL of the Cloud Run service."
}