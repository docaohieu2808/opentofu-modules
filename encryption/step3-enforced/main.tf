# Step 3: migration finished. Drop the fallback and set enforced = true so OpenTofu refuses to
# read or write anything that is not encrypted with the key below.
#
# Production alternatives to a passphrase are the aws_kms, gcp_kms and openbao key providers, e.g.
#   key_provider "gcp_kms" "prod" { kms_encryption_key = "projects/<p>/locations/<l>/keyRings/<r>/cryptoKeys/<k>" }
# and key rotation chains the old method as `fallback` of the new one.
terraform {
  required_version = ">= 1.10"

  encryption {
    key_provider "pbkdf2" "lab" {
      passphrase = var.passphrase
    }

    method "aes_gcm" "lab" {
      keys = key_provider.pbkdf2.lab
    }

    state {
      method   = method.aes_gcm.lab
      enforced = true
    }
  }
}

variable "passphrase" {
  type      = string
  sensitive = true
}

resource "terraform_data" "secret_holder" {
  input = "this-text-must-not-appear-in-an-encrypted-state"
}
