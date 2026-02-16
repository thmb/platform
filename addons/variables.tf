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

# ==============================================================================
# CERTIFICATE MANAGER
# ==============================================================================

variable "certificate_chart_version" {
  description = "Cert-Manager Helm chart version."
  default     = "v1.19.2"
  type        = string
}

variable "certificate_email" {
  description = "Cert-Manager email address."
  default     = "admin@thau.tech"
  type        = string
}

# ==============================================================================
# DATABASE OPERATOR
# ==============================================================================

variable "database_namespace" {
  description = "Kubernetes namespace for CNPG operator."
  default     = "cnpg-system"
  type        = string
}

variable "database_image" {
  description = "CNPG operator image repository."
  default     = "ghcr.io/cloudnative-pg/cloudnative-pg"
  type        = string
}

variable "database_tag" {
  description = "CNPG operator image tag."
  default     = "1.28.0"
  type        = string
}

variable "database_chart" {
  description = "CloudNativePG Helm chart version."
  default     = "0.27.0"
  type        = string
}

# ==============================================================================
# OBJECTSTORE OPERATOR
# ==============================================================================

variable "objectstore_namespace" {
  description = "Kubernetes namespace for SeaweedFS operator."
  default     = "seaweedfs-operator"
  type        = string
}

variable "objectstore_chart_version" {
  description = "SeaweedFS operator Helm chart version."
  default     = "0.1.12"
  type        = string
}

variable "objectstore_webhook_enabled" {
  description = "Enable SeaweedFS operator webhooks. Note: Should be false initially due to cert issues."
  default     = false
  type        = bool
}
