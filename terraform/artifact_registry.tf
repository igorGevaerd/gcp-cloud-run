resource "google_artifact_registry_repository" "repo" {
  repository_id = var.service_name
  format        = "DOCKER"
  location      = var.region

  depends_on = [google_project_service.artifact_registry_api]
}
