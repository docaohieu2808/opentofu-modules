# L5: OpenTofu Native Testing — improvements over Terraform
#
# OpenTofu 1.7+ enhancements vs Terraform:
#   - `expect_failures` on specific checks (not just whole run)
#   - `tofu test` supports provider mocking (mock_provider block)
#   - Better variable override ergonomics in run blocks
#
# Run with: tofu test
# (from repo root, or pass -chdir=tests/)

# Mock the Google provider so no real GCP calls are made
mock_provider "google" {
  mock_resource "google_compute_instance" {
    defaults = {
      instance_id = "1234567890"
      self_link   = "https://www.googleapis.com/compute/v1/projects/iac-devops-484714/zones/us-central1-a/instances/dev-web-01"
      network_interface = [
        {
          network_ip = "10.10.0.2"
          access_config = [
            { nat_ip = "34.0.0.1" }
          ]
        }
      ]
      machine_type = "e2-micro"
      zone         = "us-central1-a"
      name         = "dev-web-01"
    }
  }

  mock_resource "google_compute_disk" {
    defaults = {
      self_link = "https://www.googleapis.com/compute/v1/projects/iac-devops-484714/zones/us-central1-a/disks/dev-web-01-data"
    }
  }
}

# --- Test 1: Basic instance creation with defaults ---
run "test_compute_instance_defaults" {
  command = plan

  module {
    source = "../modules/gcp-compute"
  }

  variables {
    project_id = "iac-devops-484714"
    name       = "dev-web-01"
    zone       = "us-central1-a"
  }

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

# --- Test 2: Validate name format — expect validation failure ---
run "test_compute_name_validation_rejects_uppercase" {
  command = plan

  module {
    source = "../modules/gcp-compute"
  }

  variables {
    project_id = "iac-devops-484714"
    name       = "Invalid_Name_With_Underscores"
    zone       = "us-central1-a"
  }

  # OpenTofu: expect_failures targets the specific check that should fail
  expect_failures = [
    var.name,
  ]
}

# --- Test 3: No public IP when disabled ---
run "test_compute_no_public_ip" {
  command = plan

  module {
    source = "../modules/gcp-compute"
  }

  variables {
    project_id       = "iac-devops-484714"
    name             = "dev-internal-01"
    zone             = "us-central1-a"
    enable_public_ip = false
  }

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 0
    error_message = "No access_config block should exist when enable_public_ip is false"
  }
}

# --- Test 4: Additional disks attach correctly ---
run "test_compute_additional_disks" {
  command = plan

  module {
    source = "../modules/gcp-compute"
  }

  variables {
    project_id = "iac-devops-484714"
    name       = "dev-data-01"
    zone       = "us-central1-a"
    additional_disks = [
      { name = "data", size_gb = 100, type = "pd-ssd" }
    ]
  }

  assert {
    condition     = length(google_compute_disk.additional) == 1
    error_message = "One additional disk should be created"
  }
}
