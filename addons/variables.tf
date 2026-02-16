variable "kubernetes_host" {
  description = "Kubernetes API server host."
  default     = "http://localhost:6443"
  type        = string
}

variable "kubernetes_token" {
  description = "Kubernetes API server token."
  nullable    = false
  sensitive   = true
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

variable "install_certificate_manager" {
  description = "Whether to install Cert-Manager."
  default     = true
  type        = bool
}

variable "certificate_chart_version" {
  description = "Cert-Manager Helm chart version."
  default     = "v1.19.3"
  type        = string
}

variable "certificate_issuer_email" {
  description = "Cert-Manager email address."
  default     = "admin@thau.tech"
  type        = string
}

# ==============================================================================
# DATABASE OPERATOR
# ==============================================================================

variable "install_database_operator" {
  description = "Whether to install CNPG operator."
  default     = true
  type        = bool
}

variable "database_chart_version" {
  description = "CloudNativePG operator Helm chart version."
  default     = "0.27.1"
  type        = string
}

# ==============================================================================
# OBJECTSTORE OPERATOR
# ==============================================================================

variable "install_objectstore_operator" {
  description = "Whether to install SeaweedFS operator."
  default     = true
  type        = bool
}

variable "objectstore_chart_version" {
  description = "SeaweedFS operator Helm chart version."
  default     = "0.1.13"
  type        = string
}
