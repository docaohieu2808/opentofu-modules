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
  description = "Path to (or contents of) a GCP service account key. Empty means Application Default Credentials."
  type        = string
  default     = ""
}

variable "ssh_source_ranges" {
  description = "Source ranges allowed to SSH to the instance (never 0.0.0.0/0, the network module rejects it)"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "state_encryption_passphrase" {
  description = "Passphrase for the PBKDF2 key that encrypts state and plan files. No default on purpose: export TF_VAR_state_encryption_passphrase."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_encryption_passphrase) >= 16
    error_message = "Use a passphrase of at least 16 characters."
  }
}
