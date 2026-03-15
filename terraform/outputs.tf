output "service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.app.uri
}

output "artifact_registry_repository_url" {
  description = "Base URL for the Artifact Registry Docker repository (use with docker push)."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.service_name}"
}

output "image_url" {
  description = "The full Docker image URL currently deployed to Cloud Run."
  value       = local.image_url
}
