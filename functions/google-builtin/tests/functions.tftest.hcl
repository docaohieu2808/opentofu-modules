run "google_functions_parse_ids_offline" {
  command = apply

  assert {
    condition     = output.region == "us-central1" && output.instance_name == "web-1" && output.project == "example-lab-project"
    error_message = "provider::google functions returned unexpected values"
  }
}
