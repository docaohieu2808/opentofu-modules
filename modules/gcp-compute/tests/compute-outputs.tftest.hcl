# command = apply against a mocked provider: outputs are built from the mock's computed values,
# so the module's output wiring can be tested with no cloud. Each test file has its own mocks.
mock_provider "google" {
  # Values the real API would compute. With command = apply the mock supplies them, which
  # lets us assert the module's outputs without a cloud.
  mock_resource "google_compute_instance" {
    defaults = {
      instance_id = "1234567890"
      self_link   = "https://www.googleapis.com/compute/v1/projects/example-lab-project/zones/us-central1-a/instances/dev-web-01"
      # Blocks are mocked with objects, not lists.
      network_interface = {
        network_ip    = "10.10.0.2"
        access_config = { nat_ip = "203.0.113.10" }
      }
    }
  }
}

variables {
  project_id = "example-lab-project"
  name       = "dev-web-01"
  zone       = "us-central1-a"
}

run "outputs_expose_the_instance_addresses" {
  command = apply

  assert {
    condition     = output.internal_ip == "10.10.0.2" && output.external_ip == "203.0.113.10"
    error_message = "Outputs must come from the instance network_interface"
  }

  assert {
    condition     = output.ansible_inventory.host == "203.0.113.10" && output.ansible_inventory.name == "dev-web-01"
    error_message = "ansible_inventory should prefer the public address"
  }
}
