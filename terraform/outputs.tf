output "rails_api_url" {
  value = google_cloud_run_v2_service.rails_api.uri
}

output "front_url" {
  value = google_cloud_run_v2_service.front.uri
}