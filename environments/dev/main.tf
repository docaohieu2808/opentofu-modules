# L3: a dev environment composed from the L2 modules, with OpenTofu state encryption (L4).
terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }

  # State and plan files are encrypted with AES-GCM; the key is derived (PBKDF2) from a passphrase
  # that has NO default: export TF_VAR_state_encryption_passphrase (16+ characters) first.
  # Variables inside the encryption block need OpenTofu >= 1.9.
  # `enforced = true` makes OpenTofu refuse to read unencrypted state. To adopt encryption on an
  # existing unencrypted state use the migration steps in ../../encryption/.
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method   = method.aes_gcm.state_method
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state_method
      enforced = true
    }
  }

  # Partial configuration: the bucket is not committed. Provide it at init time:
  #   tofu init -backend-config="bucket=<your-state-bucket>"
  # (CI and local experiments use `tofu init -backend=false`.)
  backend "gcs" {
    prefix = "opentofu-modules/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  # null -> Application Default Credentials; a path or JSON -> that service account key
  credentials = var.credentials_file != "" ? var.credentials_file : null
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
  ssh_source_ranges = var.ssh_source_ranges
  enable_http       = false
  enable_https      = false
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

  # Lab settings: easy to destroy. Production would set this to true.
  deletion_protection = false
}

module "assets_bucket" {
  source = "../../modules/gcp-storage"

  project_id    = var.project_id
  bucket_name   = "${var.env}-${var.project_id}-assets"
  location      = var.region
  storage_class = "STANDARD"

  # Lab settings: the bucket may be deleted with its objects.
  force_destroy      = true
  versioning_enabled = false
  labels             = { env = var.env }
}
