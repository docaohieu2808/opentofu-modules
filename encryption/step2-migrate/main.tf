# Step 2: adopt encryption without losing the existing (unencrypted) state.
# The "unencrypted" method is only a *fallback* for reading old state; everything that is written
# from now on is AES-GCM encrypted.
terraform {
  required_version = ">= 1.10"

  encryption {
    key_provider "pbkdf2" "lab" {
      passphrase = var.passphrase
    }

    method "aes_gcm" "lab" {
      keys = key_provider.pbkdf2.lab
    }

    method "unencrypted" "legacy" {}

    state {
      method = method.aes_gcm.lab

      fallback {
        method = method.unencrypted.legacy
      }
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
