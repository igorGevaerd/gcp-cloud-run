# Workload Identity Federation — allows GitHub Actions to authenticate
# to GCP without a long-lived service account key
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  disabled                  = false

  depends_on = [google_project_service.iamcredentials_api]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Restrict to this repository only
  attribute_condition = "assertion.repository == 'igorGevaerd/gcp-cloud-run'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

data "google_service_account" "github_actions" {
  account_id = "github-actions-tf"
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = data.google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/igorGevaerd/gcp-cloud-run"
}
