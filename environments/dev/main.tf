terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  # L4: OpenTofu-unique state encryption (not available in Terraform)
  # Uses AES-GCM with a passphrase-derived key via PBKDF2.
  # To activate: set env var TOFU_ENCRYPTION_PASSPHRASE before running tofu.
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method = method.aes_gcm.state_method
      # enforced = true  # uncomment to reject unencrypted state reads
    }

    plan {
      method = method.aes_gcm.state_method
    }
  }

  backend "gcs" {
    bucket = "iac-devops-484714-tofu-state"
    prefix = "opentofu-modules/dev"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}

module "network" {
  source = "../../modules/gcp-network"

  project_id   = var.project_id
  region       = var.region
  network_name = "${var.env}-vpc"

  subnets = [
    {
      name          = "${var.env}-subnet-main"
      ip_cidr_range = "10.10.0.0/24"
    }
  ]

  enable_ssh        = true
  ssh_source_ranges = ["0.0.0.0/0"]
  enable_http       = false
  enable_https      = false

  labels = { env = var.env }
}

module "web_server" {
  source = "../../modules/gcp-compute"

  project_id   = var.project_id
  zone         = var.zone
  name         = "${var.env}-web-01"
  machine_type = "e2-micro"

  network    = module.network.network_name
  subnetwork = "${var.env}-subnet-main"
  tags       = ["ssh", "http-server"]
  labels     = { env = var.env, role = "web" }

  enable_public_ip = true
  deletion_protection = false
}

module "assets_bucket" {
  source = "../../modules/gcp-storage"

  project_id    = var.project_id
  bucket_name   = "${var.project_id}-${var.env}-assets"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true

  versioning_enabled = false
  labels             = { env = var.env }
}
