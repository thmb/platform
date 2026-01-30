terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket  = "thmb-state"
    key     = "platform/github/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
  }
}

provider "github" {
  token = var.access_token
  owner = "<user-or-org-name>"
}
