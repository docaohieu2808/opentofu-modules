variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "iac-devops-484714"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

variable "credentials_file" {
  description = "Path to GCP service account JSON credentials"
  type        = string
  default     = "/home/hieudc/iac-devops-terraform.json"
}

# L4: State encryption passphrase — inject via env var TF_VAR_state_encryption_passphrase
variable "state_encryption_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2/AES-GCM)"
  type        = string
  sensitive   = true
  default     = "change-me-use-env-var"
}
