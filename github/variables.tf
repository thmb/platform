variable "access_token" {
  description = "GitHub Personal Access Token with repository scope."
  sensitive   = true
  type        = string
}

variable "target_repositories" {
  description = "Target repositories to create the secrets in."
  default     = ["frontend", "backend"]
  type        = list(string)
}
