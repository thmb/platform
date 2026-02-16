output "server_id" {
  description = "K3S server ID"
  value       = hcloud_server.cluster.id
}

output "public_ip" {
  description = "Public IP address"
  value       = hcloud_primary_ip.cluster.ip_address
}

output "kubernetes_host" {
  description = "Kubernetes host"
  value       = data.external.cluster_config.result.host
}

output "kubernetes_token" {
  description = "Kubernetes token"
  value       = data.external.cluster_config.result.token
  sensitive   = true
}

output "kubernetes_certificate" {
  description = "Kubernetes certificate"
  value       = data.external.cluster_config.result.certificate
}
