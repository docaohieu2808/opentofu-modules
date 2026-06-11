terraform {
  required_version = ">= 1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }
}

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  for_each = { for s in var.subnets : s.name => s }

  project       = var.project_id
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.this.id

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_firewall" "ssh" {
  count = var.enable_ssh ? 1 : 0

  project  = var.project_id
  name     = "${var.network_name}-allow-ssh"
  network  = google_compute_network.this.id
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "http" {
  count = var.enable_http ? 1 : 0

  project  = var.project_id
  name     = "${var.network_name}-allow-http"
  network  = google_compute_network.this.id
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.http_source_ranges
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "https" {
  count = var.enable_https ? 1 : 0

  project  = var.project_id
  name     = "${var.network_name}-allow-https"
  network  = google_compute_network.this.id
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.http_source_ranges
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "custom" {
  for_each = { for r in var.firewall_rules : r.name => r }

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  network     = google_compute_network.this.id
  direction   = each.value.direction
  priority    = each.value.priority

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  source_ranges      = each.value.direction == "INGRESS" ? each.value.ranges : []
  destination_ranges = each.value.direction == "EGRESS" ? each.value.ranges : []
  target_tags        = each.value.target_tags
  source_tags        = each.value.source_tags
}
