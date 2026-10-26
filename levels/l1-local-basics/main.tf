# Level 1: resources, variables, outputs, providers - everything runs on your laptop with OpenTofu.
# No cloud account: the random and local providers only need the machine you are on.
terraform {
  required_version = ">= 1.10"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

variable "greeting" {
  description = "First word of the generated file"
  type        = string
  default     = "hello"

  validation {
    condition     = can(regex("^[a-z]{2,12}$", var.greeting))
    error_message = "greeting must be 2-12 lowercase letters."
  }
}

# A resource with no dependencies: Terraform generates a random pair of words once and
# remembers it in state, so re-running plan shows no change.
resource "random_pet" "name" {
  length = 2
}

# A resource that depends on another one through an attribute reference.
resource "local_file" "greeting" {
  filename = "${path.module}/out/${random_pet.name.id}.txt"
  content  = "${var.greeting}, ${random_pet.name.id}\n"
}

output "pet_name" {
  description = "The generated name"
  value       = random_pet.name.id
}

output "file_path" {
  description = "Where the greeting was written"
  value       = local_file.greeting.filename
}
