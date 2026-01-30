terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket  = "thmb-state"
    key     = "platform/addons/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }
}


provider "kubernetes" {
  host                   = var.kubernetes_host
  token                  = var.kubernetes_token
  insecure               = contains(["localhost", "127.0.0.1"], var.kubernetes_host)
  cluster_ca_certificate = var.kubernetes_certificate != "" ? base64decode(var.kubernetes_certificate) : null
}


provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_host
    token                  = var.kubernetes_token
    insecure               = contains(["localhost", "127.0.0.1"], var.kubernetes_host)
    cluster_ca_certificate = var.kubernetes_certificate != "" ? base64decode(var.kubernetes_certificate) : null
  }
}
