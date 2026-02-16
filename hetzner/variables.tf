variable "project_name" {
  description = "Project name."
  default     = "thmb"
  type        = string
}

variable "default_location" {
  description = "Hetzner Cloud location."
  default     = "nbg1" # Nuremberg, Germany
  type        = string
}

variable "instance_type" {
  description = "Hetzner Cloud server type for K3S cluster."
  default     = "cx32" # 4 vcpu, 8gb ram
  type        = string
}

variable "system_image" {
  description = "OS image for the server."
  default     = "debian-13"
  type        = string
}

variable "kubernetes_version" {
  description = "K3S Kubernetes version."
  default     = "v1.35.1+k3s1"
  type        = string
}

variable "cidr_blocks" {
  description = "CIDR blocks allowed to access SSH and K3S API."
  default     = ["0.0.0.0/0", "::/0"]
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
