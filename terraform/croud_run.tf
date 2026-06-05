resource "google_cloud_run_v2_service" "rails_api" {
  name     = "rails-sandbox-api"
  location = var.region

  template {
    service_account = google_service_account.rails_runner.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.rails_image
      ports { container_port = 8080 }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "RAILS_ENV"
        value = "production"
      }
      env {
        name  = "RAILS_LOG_TO_STDOUT"
        value = "true"
      }

      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "ALLOWED_ORIGINS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.allowed_origins.secret_id
            version = "latest"
          }
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "rails_api_public" {
  service  = google_cloud_run_v2_service.rails_api.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service" "front" {
  name     = "rails-sandbox-front"
  location = var.region

  template {
    containers {
      image = var.front_image
      ports { container_port = 3000 }

      env {
        name  = "NEXT_PUBLIC_GRAPHQL_ENDPOINT"
        value = "${google_cloud_run_v2_service.rails_api.uri}/graphql"
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "front_public" {
  service  = google_cloud_run_v2_service.front.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}