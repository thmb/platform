terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket  = "thmb-state"
    key     = "platform/cloudflare/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.15.0"
    }
  }
}


provider "cloudflare" {
  api_token = var.api_token
}
