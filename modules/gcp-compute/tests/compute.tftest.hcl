# OpenTofu unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory:  tofu init -backend=false && tofu test
# Tests live next to the module so assertions can see its resources directly.
# (Computed-value outputs are covered in compute-outputs.tftest.hcl.)
mock_provider "google" {}

variables {
  project_id = "example-lab-project"
  name       = "dev-web-01"
  zone       = "us-central1-a"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_compute_instance.this.machine_type == "e2-medium"
    error_message = "Default machine type should be e2-medium"
  }

  assert {
    condition     = google_compute_instance.this.deletion_protection == false
    error_message = "Default deletion_protection should be false"
  }

  assert {
    condition     = length(google_compute_instance.this.boot_disk) == 1
    error_message = "Instance must have exactly one boot disk"
  }
}

run "name_with_uppercase_and_underscores_is_rejected" {
  command = plan

  variables {
    name = "Invalid_Name_With_Underscores"
  }

  # expect_failures names the object whose validation must fail; the run passes only if it does.
  expect_failures = [var.name]
}

run "private_instance_has_no_access_config" {
  command = plan

  variables {
    name             = "dev-internal-01"
    enable_public_ip = false
  }

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 0
    error_message = "No access_config block when enable_public_ip is false"
  }
}

run "additional_disks_are_created" {
  command = plan

  variables {
    name             = "dev-data-01"
    additional_disks = [{ name = "data", size_gb = 100, type = "pd-ssd" }]
  }

  assert {
    condition     = length(google_compute_disk.additional) == 1 && google_compute_disk.additional["data"].size == 100
    error_message = "One 100 GB additional disk expected"
  }
}
