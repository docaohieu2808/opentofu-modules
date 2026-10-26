# L6b: a provider-defined function from OUR provider (../../custom-provider).
#
# The provider is not published anywhere. Build it and point OpenTofu at the binary with
# dev_overrides in the CLI configuration (see the repository README):
#
#   cd custom-provider && go build -o bin/terraform-provider-devops .
#   printf 'provider_installation {\n  dev_overrides {\n    "registry.opentofu.org/lab/devops" = "%s"\n  }\n  direct {}\n}\n' \
#     "$PWD/bin" > /tmp/devops.tofurc
#   TF_CLI_CONFIG_FILE=/tmp/devops.tofurc tofu -chdir=../functions/custom apply
#
# With dev_overrides there is no `tofu init` step for this provider (OpenTofu warns about it).
terraform {
  required_version = ">= 1.10"

  required_providers {
    # tflint-ignore: terraform_required_providers
    devops = {
      source = "lab/devops" # never published: resolved by dev_overrides, so no version constraint
    }
  }
}

locals {
  raw_labels = {
    "Environment" = "Dev/Staging"
    "Team Name"   = "Platform Ops"
    "Cost_Center" = "ENG-001"
    "managed by"  = "OpenTofu 1.13"
  }
}

output "gcp_labels" {
  description = "Label keys and values made GCP-safe by the provider function"
  value = {
    for k, v in local.raw_labels :
    provider::devops::sanitise_label(k) => provider::devops::sanitise_label(v)
  }
}

# The provider's resource and data source, also local-only.
resource "devops_config_file" "greeting" {
  path    = "${path.module}/out/greeting.txt"
  content = "hello from a custom provider\n"
}

data "devops_file_info" "greeting" {
  path = devops_config_file.greeting.path
}

output "greeting_sha256" {
  value = data.devops_file_info.greeting.sha256
}
