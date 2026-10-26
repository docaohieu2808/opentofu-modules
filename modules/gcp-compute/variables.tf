variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "name" {
  description = "Name of the compute instance"
  type        = string

  # OpenTofu: validation block with custom error message
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "Instance name must be 2-63 chars, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "VPC network name or self_link"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name or self_link"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Network tags for the instance"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Metadata key/value pairs for the instance"
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Startup script content (bash)"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email for the instance"
  type        = string
  default     = ""
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "allow_stopping_for_update" {
  description = "Allow stopping instance for update"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "enable_public_ip" {
  description = "Assign an ephemeral public IP"
  type        = bool
  default     = true
}

variable "static_ip" {
  description = "Static external IP address (leave empty for ephemeral)"
  type        = string
  default     = ""
}

variable "additional_disks" {
  description = "Additional data disks to attach"
  type = list(object({
    name        = string
    size_gb     = number
    type        = optional(string, "pd-balanced")
    auto_delete = optional(bool, true)
  }))
  default = []
}
