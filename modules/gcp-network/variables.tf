variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.network_name))
    error_message = "Network name must be 2-63 chars, lowercase letters, numbers, and hyphens only."
  }
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = optional(string)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = []
}

variable "auto_create_subnetworks" {
  description = "Auto create subnetworks"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "firewall_rules" {
  description = "List of custom firewall rules"
  type = list(object({
    name        = string
    description = optional(string, "")
    direction   = optional(string, "INGRESS")
    priority    = optional(number, 1000)
    ranges      = list(string)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    target_tags = optional(list(string), [])
    source_tags = optional(list(string), [])
  }))
  default = []
}

variable "enable_ssh" {
  description = "Enable SSH firewall rule (port 22)"
  type        = bool
  default     = true
}

variable "enable_http" {
  description = "Enable HTTP firewall rule (port 80)"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS firewall rule (port 443)"
  type        = bool
  default     = false
}

variable "ssh_source_ranges" {
  description = "Source IP ranges for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_source_ranges" {
  description = "Source IP ranges for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
