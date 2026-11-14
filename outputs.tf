output "web_public_ip" {
  description = "Public IPv4 address of the web VM."
  value       = yandex_compute_instance.web.network_interface[0].nat_ip_address
}

output "web_private_ip" {
  description = "Private IPv4 address of the web VM."
  value       = yandex_compute_instance.web.network_interface[0].ip_address
}

output "worker_private_ip" {
  description = "Private IPv4 address of the worker VM."
  value       = yandex_compute_instance.worker.network_interface[0].ip_address
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = yandex_vpc_network.this.id
}

output "subnet_id" {
  description = "ID of the created subnet."
  value       = yandex_vpc_subnet.this.id
}

output "web_instance_id" {
  description = "ID of the web VM."
  value       = yandex_compute_instance.web.id
}

output "worker_instance_id" {
  description = "ID of the worker VM."
  value       = yandex_compute_instance.worker.id
}
