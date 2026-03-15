variable "project_id" {
  description = "The GCP project ID where all resources will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for Cloud Run and Artifact Registry (e.g. us-central1)."
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name used for the Cloud Run service, Artifact Registry repo, and service account."
  type        = string
  default     = "gcp-cloud-run"
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g. latest, v1.0.0, or a short Git SHA)."
  type        = string
  default     = "latest"
}
