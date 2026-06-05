resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "database_url" {
  secret_id = "database-url"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "allowed_origins" {
  secret_id = "allowed-origins"
  replication {
    auto {}
  }
}