locals {
  image_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.service_name}/${var.service_name}:${var.image_tag}"
}

resource "google_project_service" "cloudresourcemanager_api" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repo" {
  repository_id = var.service_name
  format        = "DOCKER"
  location      = var.region

  depends_on = [google_project_service.artifact_registry_api]
}

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

  depends_on = [google_project_service.run_api]
}

resource "google_project_service" "apigateway_api" {
  service            = "apigateway.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicemanagement_api" {
  service            = "servicemanagement.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicecontrol_api" {
  service            = "servicecontrol.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "apikeys_api" {
  service            = "apikeys.googleapis.com"
  disable_on_destroy = false
}

# Dedicated service account for the gateway to invoke Cloud Run
resource "google_service_account" "api_gateway" {
  account_id   = "${var.service_name}-gw-sa"
  display_name = "${var.service_name} API Gateway service account"
}

# Cloud Run is private — only the gateway SA can invoke it
resource "google_cloud_run_v2_service_iam_member" "gateway_invoker" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_gateway.email}"
}

locals {
  openapi_spec = jsonencode({
    swagger = "2.0"
    info = {
      title   = var.service_name
      version = "1.0"
    }
    schemes  = ["https"]
    produces = ["application/json"]
    # Route all paths to Cloud Run; append the request path to the base URL
    "x-google-backend" = {
      address          = google_cloud_run_v2_service.app.uri
      path_translation = "APPEND_PATH_TO_ADDRESS"
      jwt_audience     = google_cloud_run_v2_service.app.uri
    }
    securityDefinitions = {
      api_key = {
        type = "apiKey"
        name = "x-api-key"
        in   = "header"
      }
    }
    paths = {
      "/" = {
        get = {
          operationId = "getRoot"
          responses   = { "200" = { description = "OK" } }
        }
      }
      "/health" = {
        get = {
          operationId = "getHealth"
          responses   = { "200" = { description = "OK" } }
        }
      }
      "/random-int" = {
        get = {
          operationId = "getRandomInt"
          security    = [{ api_key = [] }]
          responses   = { "200" = { description = "OK" } }
        }
      }
      "/random-name-string" = {
        get = {
          operationId = "getRandomName"
          security    = [{ api_key = [] }]
          responses   = { "200" = { description = "OK" } }
        }
      }
    }
  })
}

resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = var.service_name

  depends_on = [google_project_service.apigateway_api]
}

resource "google_project_service" "api_gateway_managed_service" {
  service            = google_api_gateway_api.api.managed_service
  disable_on_destroy = false

  depends_on = [google_api_gateway_api.api]
}

resource "google_api_gateway_api_config" "api_config" {
  provider             = google-beta
  api                  = google_api_gateway_api.api.api_id
  api_config_id_prefix = "${var.service_name}-"

  openapi_documents {
    document {
      path     = "openapi.json"
      contents = base64encode(local.openapi_spec)
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.api_gateway.email
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_project_service.servicemanagement_api,
    google_project_service.servicecontrol_api,
  ]
}

resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = var.service_name
  region     = var.region

  depends_on = [google_project_service.apigateway_api]
}

resource "google_apikeys_key" "api_key" {
  provider     = google-beta
  name         = "${var.service_name}-key"
  display_name = "${var.service_name} API key"

  restrictions {
    api_targets {
      service = google_api_gateway_api.api.managed_service
    }
  }

  depends_on = [google_project_service.apikeys_api]
}
