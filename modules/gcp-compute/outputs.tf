output "instance_id" {
  description = "The server-assigned unique ID of the instance"
  value       = google_compute_instance.this.instance_id
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "Self link of the compute instance"
  value       = google_compute_instance.this.self_link
}

output "internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "External (public) IP address of the instance"
  value       = var.enable_public_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : null
}

output "zone" {
  description = "Zone where the instance is deployed"
  value       = google_compute_instance.this.zone
}

output "ansible_inventory" {
  description = "Ansible inventory entry for this instance"
  value = {
    host         = var.enable_public_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : google_compute_instance.this.network_interface[0].network_ip
    internal_ip  = google_compute_instance.this.network_interface[0].network_ip
    name         = google_compute_instance.this.name
    zone         = google_compute_instance.this.zone
    machine_type = google_compute_instance.this.machine_type
  }
}
