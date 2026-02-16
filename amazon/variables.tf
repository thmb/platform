variable "project_name" {
  description = "Project name."
  default     = "thmb"
  type        = string
}

variable "default_location" {
  description = "AWS region."
  default     = "sa-east-1" # South America (São Paulo)
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for K3S cluster."
  default     = "t3a.large" # 2 vcpu, 8gb ram
  type        = string
}

variable "system_image" {
  description = "OS image for the server."
  default     = "debian-13-backports"
  type        = string
}

variable "kubernetes_version" {
  description = "K3S Kubernetes version."
  default     = "v1.35.1+k3s1"
  type        = string
}

variable "cidr_blocks" {
  description = "CIDR blocks allowed to access SSH and K3S API."
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "SSH private key content."
  type        = string
  sensitive   = true
}
