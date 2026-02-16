terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket  = "thmb-state"
    key     = "platform/amazon/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}


provider "aws" {
  # Authenticates via AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
  region = var.default_location
}
