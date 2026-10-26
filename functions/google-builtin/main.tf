# L6a: provider-defined functions that already ship in the google provider.
# They are called as provider::google::<name>(...) and run inside the provider binary, so they work
# offline: no credentials, no provider configuration, no API call. Terraform 1.8+ supports them too.
terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

locals {
  instance_id = "projects/example-lab-project/zones/us-central1-a/instances/web-1"
}

output "region" {
  description = "Region parsed from a zone name"
  value       = provider::google::region_from_zone("us-central1-a")
}

output "instance_name" {
  description = "Resource name parsed from a full resource ID"
  value       = provider::google::name_from_id(local.instance_id)
}

output "project" {
  description = "Project parsed from a full resource ID"
  value       = provider::google::project_from_id(local.instance_id)
}
