terraform {
  required_version = ">= 1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }
}

resource "google_storage_bucket" "this" {
  project  = var.project_id
  name     = var.bucket_name
  location = var.location

  storage_class               = var.storage_class
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access

  labels = var.labels

  versioning {
    enabled = var.versioning_enabled
  }

  public_access_prevention = var.public_access_prevention

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.storage_class
      }
      condition {
        age                = lifecycle_rule.value.age_days
        num_newer_versions = lifecycle_rule.value.num_newer_versions
        with_state         = lifecycle_rule.value.with_state
      }
    }
  }

  dynamic "cors" {
    for_each = var.cors_rules
    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy_seconds > 0 ? [1] : []
    content {
      retention_period = var.retention_policy_seconds
    }
  }

  dynamic "website" {
    for_each = var.enable_website ? [1] : []
    content {
      main_page_suffix = var.website_main_page_suffix
      not_found_page   = var.website_not_found_page
    }
  }
}

resource "google_storage_bucket_iam_binding" "this" {
  for_each = { for b in var.iam_bindings : b.role => b }

  bucket  = google_storage_bucket.this.name
  role    = each.value.role
  members = each.value.members
}
