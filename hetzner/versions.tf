terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket  = "thmb-state"
    key     = "platform/hetzner/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.1"
    }
  }
}


provider "hcloud" {
  token = var.hetzner_api_token # HCLOUD_TOKEN
}
