variable "project_id" {
  description = "GCP project ID — set via TF_VAR_project_id or -var flag"
  type        = string
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
  description = "Path to GCP service account JSON credentials — set via GOOGLE_APPLICATION_CREDENTIALS or TF_VAR_credentials_file"
  type        = string
  default     = ""
}

# L4: State encryption passphrase — inject via env var TF_VAR_state_encryption_passphrase
variable "state_encryption_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2/AES-GCM)"
  type        = string
  sensitive   = true
  default     = "change-me-use-env-var"
}
