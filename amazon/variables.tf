variable "aws_region" {
  description = "AWS region."
  default     = "sa-east-1"
  type        = string
}

variable "project_name" {
  description = "Project name."
  default     = "thmb"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for K3S cluster."
  default     = "t3a.large" # 2 vcpu, 8gb ram
  type        = string
}

variable "disk_size" {
  description = "Disk size in GB."
  default     = 32
  type        = number
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks able to SSH into the instance."
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
