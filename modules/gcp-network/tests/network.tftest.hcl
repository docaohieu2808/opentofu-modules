# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id   = "example-lab-project"
  network_name = "dev-vpc"
}

run "ssh_rule_defaults_to_private_ranges" {
  command = plan

  variables {
    enable_ssh = true
  }

  assert {
    condition     = !contains(google_compute_firewall.ssh[0].source_ranges, "0.0.0.0/0")
    error_message = "SSH must never default to the whole internet"
  }

  assert {
    condition     = contains(google_compute_firewall.ssh[0].source_ranges, "10.0.0.0/8")
    error_message = "Default SSH ranges should be the RFC 1918 private ranges"
  }
}

run "ssh_open_to_internet_is_rejected" {
  command = plan

  variables {
    enable_ssh        = true
    ssh_source_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_source_ranges]
}

run "only_ssh_is_on_by_default" {
  command = plan

  assert {
    condition     = length(google_compute_firewall.ssh) == 1 && length(google_compute_firewall.http) == 0 && length(google_compute_firewall.https) == 0
    error_message = "HTTP and HTTPS rules are opt-in; SSH (private ranges only) is the single default"
  }
}

run "subnets_are_created_per_entry" {
  command = plan

  variables {
    subnets = [
      { name = "dev-subnet-a", ip_cidr_range = "10.10.0.0/24", region = "us-central1" },
      { name = "dev-subnet-b", ip_cidr_range = "10.10.1.0/24", region = "us-east1" },
    ]
  }

  assert {
    condition     = length(google_compute_subnetwork.this) == 2
    error_message = "Expected one subnetwork per entry"
  }

  assert {
    condition     = google_compute_subnetwork.this["dev-subnet-b"].region == "us-east1"
    error_message = "Per-subnet region must be honoured"
  }
}
