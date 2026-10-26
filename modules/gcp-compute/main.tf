terraform {
  required_version = ">= 1.10"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  tags   = var.tags
  labels = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = var.additional_disks
    content {
      source = google_compute_disk.additional[attached_disk.value.name].self_link
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork != "" ? var.subnetwork : null

    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        nat_ip = var.static_ip != "" ? var.static_ip : null
      }
    }
  }

  metadata = merge(
    var.metadata,
    var.startup_script != "" ? { startup-script = var.startup_script } : {}
  )

  dynamic "service_account" {
    for_each = var.service_account_email != "" ? [1] : []
    content {
      email  = var.service_account_email
      scopes = var.service_account_scopes
    }
  }

  allow_stopping_for_update = var.allow_stopping_for_update
  deletion_protection       = var.deletion_protection
}

resource "google_compute_disk" "additional" {
  for_each = { for d in var.additional_disks : d.name => d }

  project = var.project_id
  name    = "${var.name}-${each.value.name}"
  size    = each.value.size_gb
  type    = each.value.type
  zone    = var.zone
}
