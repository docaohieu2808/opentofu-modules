output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.this.self_link
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet name to subnet self link"
  value       = { for k, v in google_compute_subnetwork.this : k => v.self_link }
}

output "subnet_ip_ranges" {
  description = "Map of subnet name to IP CIDR range"
  value       = { for k, v in google_compute_subnetwork.this : k => v.ip_cidr_range }
}
