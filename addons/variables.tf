variable "kubernetes_host" {
  description = "Kubernetes API server host."
  default     = "http://localhost:6443"
  type        = string
}

variable "kubernetes_token" {
  description = "Kubernetes API server token."
  nullable    = false
  type        = string
}

variable "kubernetes_certificate" {
  description = "Kubernetes API server certificate."
  nullable    = false
  type        = string
}

variable "certmanager_version" {
  description = "Cert-Manager Helm chart version."
  default     = "v1.19.2"
  type        = string
}

variable "certmanager_email" {
  description = "Cert-Manager email address."
  default     = "admin@thau.tech"
  type        = string
}
