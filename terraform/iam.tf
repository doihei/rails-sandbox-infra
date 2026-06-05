resource "google_service_account" "rails_runner" {
  account_id   = "rails-runner"
  display_name = "Rails Cloud Run Service Account"
}

resource "google_secret_manager_secret_iam_member" "master_key_access" {
  secret_id = google_secret_manager_secret.rails_master_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rails_runner.email}"
}

resource "google_secret_manager_secret_iam_member" "database_url_access" {
  secret_id = google_secret_manager_secret.database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rails_runner.email}"
}

resource "google_secret_manager_secret_iam_member" "allowed_origins_access" {
  secret_id = google_secret_manager_secret.allowed_origins.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rails_runner.email}"
}

resource "google_project_iam_member" "rails_runner_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.rails_runner.email}"
}