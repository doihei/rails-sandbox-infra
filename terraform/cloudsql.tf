resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "rails-sandbox-db"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "rails" {
  name     = "rails_sandbox_production"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "rails" {
  name     = "rails_sandbox"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "postgresql://rails_sandbox:${random_password.db_password.result}@localhost/rails_sandbox_production?host=/cloudsql/${google_sql_database_instance.main.connection_name}"
}
