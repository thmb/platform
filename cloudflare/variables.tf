variable "api_token" {
  description = "API token for Cloudflare."
  nullable    = false
  type        = string
}


variable "root_domain" {
  description = "Root domain for Cloudflare DNS records."
  default     = "thau.tech"
  type        = string
}
