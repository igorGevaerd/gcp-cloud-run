resource "google_service_account" "app" {
  account_id   = "${var.service_name}-sa"
  display_name = "${var.service_name} service account"
}

resource "google_cloud_run_v2_service" "app" {
  name                = var.service_name
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.app.email

    containers {
      # Placeholder used for initial bootstrap — the deploy job updates this via gcloud run deploy
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].containers[0].image,
      template[0].labels,
      template[0].scaling,
    ]
  }

  depends_on = [google_project_service.run_api]
}

# Cloud Run is private — only the gateway SA can invoke it
resource "google_cloud_run_v2_service_iam_member" "gateway_invoker" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_gateway.email}"
}
