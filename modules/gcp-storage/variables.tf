variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket (must be globally unique)"
  type        = string
}

variable "location" {
  description = "GCS bucket location (region, dual-region, or multi-region)"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allow deletion of bucket with objects inside"
  type        = bool
  default     = false
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access (disables ACLs)"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention (enforced or inherited)"
  type        = string
  default     = "enforced"
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for object management"
  type = list(object({
    action_type        = string
    storage_class      = optional(string)
    age_days           = optional(number)
    num_newer_versions = optional(number)
    with_state         = optional(string)
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS configuration for the bucket"
  type = list(object({
    origins          = list(string)
    methods          = list(string)
    response_headers = optional(list(string), [])
    max_age_seconds  = optional(number, 3600)
  }))
  default = []
}

variable "iam_bindings" {
  description = "IAM bindings for the bucket"
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "retention_policy_seconds" {
  description = "Retention policy in seconds (0 to disable)"
  type        = number
  default     = 0
}

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "website_main_page_suffix" {
  description = "Main page suffix for static website"
  type        = string
  default     = "index.html"
}

variable "website_not_found_page" {
  description = "404 page for static website"
  type        = string
  default     = "404.html"
}
