# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id  = "example-lab-project"
  bucket_name = "dev-example-lab-project-assets"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access must be on by default"
  }

  assert {
    condition     = google_storage_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false"
  }
}

run "versioning_toggle" {
  command = plan

  variables {
    versioning_enabled = true
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "versioning_enabled=true must enable object versioning"
  }
}

run "lifecycle_rule_is_rendered" {
  command = plan

  variables {
    lifecycle_rules = [{ action_type = "Delete", age_days = 30 }]
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 1
    error_message = "Expected one lifecycle rule"
  }
}
