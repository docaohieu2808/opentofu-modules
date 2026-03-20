output "bucket_id" {
  description = "The ID of the GCS bucket"
  value       = google_storage_bucket.this.id
}

output "bucket_name" {
  description = "The name of the GCS bucket"
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "The base URL of the bucket (gs://bucket-name)"
  value       = google_storage_bucket.this.url
}

output "bucket_self_link" {
  description = "The URI of the created resource"
  value       = google_storage_bucket.this.self_link
}

output "website_endpoint" {
  description = "The website endpoint (if static website enabled)"
  value       = var.enable_website ? "https://storage.googleapis.com/${google_storage_bucket.this.name}" : null
}
