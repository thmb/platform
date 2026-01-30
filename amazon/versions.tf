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
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "platform"
      ManagedBy = "terraform"
    }
  }
}
