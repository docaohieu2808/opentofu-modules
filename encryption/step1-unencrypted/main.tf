# Step 1: the state of a project that has not adopted encryption yet.
terraform {
  required_version = ">= 1.10"
}

resource "terraform_data" "secret_holder" {
  input = "this-text-must-not-appear-in-an-encrypted-state"
}
