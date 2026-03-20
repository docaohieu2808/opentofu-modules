# L4: OpenTofu State Encryption — unique feature not available in Terraform
#
# OpenTofu 1.7+ supports encrypting state and plan files at rest.
# Supported key providers: pbkdf2, aws_kms, gcp_kms, openbao
# Supported methods:       aes_gcm
#
# This file is a standalone reference/demo. The actual encryption block
# lives in environments/dev/main.tf inside the terraform{} block.
#
# Usage:
#   export TF_VAR_state_encryption_passphrase="your-secret-passphrase"
#   tofu init && tofu apply
#
# To migrate existing unencrypted state to encrypted:
#   1. Add encryption block
#   2. Run: tofu apply -refresh=false
#
# To rotate keys, chain old key as fallback:
#   method "aes_gcm" "rotated" {
#     keys    = key_provider.pbkdf2.new_key
#     fallback { method = method.aes_gcm.old_method }
#   }

terraform {
  required_version = ">= 1.7"

  # --- Option A: Passphrase-based (PBKDF2 key derivation) ---
  # Simple, no external KMS dependency. Good for dev/CI.
  encryption {
    key_provider "pbkdf2" "dev_passphrase" {
      passphrase = var.state_encryption_passphrase

      # Optional tuning (defaults shown):
      # key_length   = 32        # bytes → AES-256
      # iterations   = 600000    # PBKDF2 iterations
      # salt_length  = 32        # bytes
      # hash_function = "sha512"
    }

    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.dev_passphrase
    }

    state {
      method   = method.aes_gcm.default
      enforced = false # set true to reject reads of unencrypted state
    }

    plan {
      method = method.aes_gcm.default
    }
  }

  # --- Option B: GCP KMS-backed key (for production) ---
  # Uncomment and replace passphrase block above with this:
  #
  # encryption {
  #   key_provider "gcp_kms" "prod_kms" {
  #     kms_encryption_key = "projects/iac-devops-484714/locations/us-central1/keyRings/tofu-ring/cryptoKeys/tofu-state-key"
  #     credentials        = file("/home/hieudc/iac-devops-terraform.json")
  #   }
  #
  #   method "aes_gcm" "kms_method" {
  #     keys = key_provider.gcp_kms.prod_kms
  #   }
  #
  #   state { method = method.aes_gcm.kms_method; enforced = true }
  #   plan  { method = method.aes_gcm.kms_method }
  # }
}

variable "state_encryption_passphrase" {
  description = "Passphrase for PBKDF2 state encryption. Set via TF_VAR_state_encryption_passphrase."
  type        = string
  sensitive   = true
}
