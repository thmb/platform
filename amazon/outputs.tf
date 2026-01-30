output "instance_id" {
  description = "K3S instance ID"
  value       = aws_instance.k3s.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_eip.cluster.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.k3s.private_ip
}

output "kubernetes_host" {
  description = "Kubernetes host"
  value       = data.external.cluster_config.result.host
}

output "kubernetes_token" {
  description = "Kubernetes token"
  value       = data.external.cluster_config.result.token
}

output "kubernetes_certificate" {
  description = "Kubernetes certificate"
  value       = data.external.cluster_config.result.certificate
}
