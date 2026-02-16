variable "hetzner_api_token" {
  description = "Hetzner Cloud API Token."
  sensitive   = true
  type        = string
}

variable "project_name" {
  description = "Project name."
  default     = "thmb"
  type        = string
}

variable "location" {
  description = "Hetzner Cloud location."
  default     = "nbg1" # Nuremberg, Germany
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type for K3S cluster."
  default     = "cx32" # 4 vcpu, 8gb ram
  type        = string
}

variable "image" {
  description = "OS image for the server."
  default     = "debian-13"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks able to SSH into the instance."
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
