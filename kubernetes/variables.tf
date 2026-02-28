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

variable "install_cert_manager" {
  description = "Whether to install Cert-Manager."
  default     = true
  type        = bool
}

variable "cert_manager_email" {
  description = "Cert-Manager email address."
  default     = "admin@thau.tech"
  type        = string
}

# ==============================================================================
# POSTGRESQL OPERATOR
# ==============================================================================

variable "install_cnpg_operator" {
  description = "Whether to install CNPG operator."
  default     = true
  type        = bool
}

# ==============================================================================
# STORAGE OPERATOR
# ==============================================================================

variable "install_ceph_operator" {
  description = "Whether to install Rook-Ceph operator."
  default     = true
  type        = bool
}
