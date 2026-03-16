output "service_url" {
  description = "The internal Cloud Run service URL (private — use gateway_url for public access)."
  value       = google_cloud_run_v2_service.app.uri
}

output "gateway_url" {
  description = "Public API Gateway URL — use this instead of the Cloud Run URL."
  value       = "https://${google_api_gateway_gateway.gateway.default_hostname}"
}

output "api_key" {
  description = "API key for protected routes (/random-int, /random-name-string). Pass as x-api-key header."
  value       = google_apikeys_key.api_key.key_string
  sensitive   = true
}

output "artifact_registry_repository_url" {
  description = "Base URL for the Artifact Registry Docker repository (use with docker push)."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.service_name}"
}

output "image_url" {
  description = "The full Docker image URL currently deployed to Cloud Run."
  value       = local.image_url
}
