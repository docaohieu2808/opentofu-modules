# L6: Provider-Defined Functions — OpenTofu 1.7+ unique feature
#
# OpenTofu 1.7 introduced the ability for providers to expose callable HCL
# functions beyond the built-in tofu stdlib. Referenced as:
#
#   provider::<provider_name>::<function_name>(args...)
#
# This is NOT available in Terraform (hashicorp/terraform does not support
# provider-contributed functions at all as of Terraform 1.x).
#
# The google provider (hashicorp/google) does not yet ship custom functions,
# so this file uses the `aws` provider pattern as a reference and demonstrates:
#   1. How to declare and call provider-defined functions
#   2. A practical pattern using built-in tofu functions to achieve the same
#      label-validation use-case without a custom provider
#
# To see a real provider-defined function in action, use the `aws` provider:
#   provider::aws::arn_parse("arn:aws:iam::123456789:role/MyRole")
#
# Reference: https://opentofu.org/docs/language/functions/providers/

terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  # credentials / project supplied via env vars or tfvars
}

# ── Pattern: provider-defined function call syntax ───────────────────────────
# When a provider exposes a function named "sanitise_label", you call it as:
#
#   local.clean = provider::google::sanitise_label("My Raw Value")
#
# The function is declared in the provider's Go SDK (see custom-provider/provider.go
# in this repo for the skeleton implementation of provider::devops::sanitise_label).

# ── Practical L6 demo: label normalisation using tofu built-ins ──────────────
# This produces the same output as the provider-defined function would,
# using tofu's own stdlib (replace, lower, regex) — runnable today with
# google provider v5+ and OpenTofu 1.7+.

locals {
  # Raw inputs that need sanitising before use as GCP labels
  raw_labels = {
    "Environment"  = "Dev/Staging"
    "Team Name"    = "Platform Ops"
    "Cost_Center"  = "ENG-001"
    "managed by"   = "OpenTofu 1.7"
  }

  # Normalise: lowercase key, replace non-alphanumeric-hyphen chars with "-"
  # GCP label keys: [a-z][a-z0-9_-]{0,62}
  # GCP label values: [a-z0-9_-]{0,63}
  normalised_labels = {
    for k, v in local.raw_labels :
    lower(replace(replace(k, " ", "-"), "_", "-")) =>
    lower(replace(replace(replace(v, " ", "-"), "/", "-"), "_", "-"))
  }

  # Validate all keys pass GCP label naming rules
  invalid_label_keys = [
    for k in keys(local.normalised_labels) : k
    if !can(regex("^[a-z][a-z0-9_-]{0,62}$", k))
  ]
}

# Fail fast at plan time if any label key is non-conformant
resource "terraform_data" "assert_valid_label_keys" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_label_keys) == 0
      error_message = "Non-conformant GCP label keys after normalisation: ${join(", ", local.invalid_label_keys)}"
    }
  }
}

output "normalised_labels" {
  description = "GCP-safe labels produced by normalisation logic (mirrors what provider::devops::sanitise_label would return)"
  value       = local.normalised_labels
}

output "label_count" {
  description = "Number of labels after normalisation"
  value       = length(local.normalised_labels)
}

# ── Note on provider-defined functions (L6) ─────────────────────────────────
# The custom-provider/ directory in this repo implements the full skeleton for
# a provider that exposes provider::devops::sanitise_label().
# Once built and installed, callers replace the locals block above with:
#
#   locals {
#     clean_team = provider::devops::sanitise_label("Platform Ops")
#   }
#
# OpenTofu resolves this at plan time via GetFunctions() / CallFunction() RPC.
# Terraform has no equivalent RPC — provider-defined functions are OpenTofu-only.
