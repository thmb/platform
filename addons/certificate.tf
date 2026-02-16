resource "kubernetes_namespace_v1" "certificate" {
  count = var.install_certificate_manager ? 1 : 0

  metadata {
    name = "certificate-system"
  }
}


resource "helm_release" "certificate" {
  count = var.install_certificate_manager ? 1 : 0

  name             = "certificate-manager"
  namespace        = kubernetes_namespace_v1.certificate[0].metadata[0].name
  create_namespace = false

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.certificate_chart_version

  timeout = 300
  atomic  = true
  wait    = true

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
      startupapicheck = {
        enabled = false
      }
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
      }
      webhook = {
        resources = {
          requests = { cpu = "10m", memory = "24Mi" }
        }
      }
      cainjector = {
        resources = {
          requests = { cpu = "10m", memory = "32Mi" }
        }
      }
    })
  ]
}


resource "terraform_data" "certificate_webhook_ready" {
  count = var.install_certificate_manager ? 1 : 0

  triggers_replace = [helm_release.certificate[0].metadata[0].revision]

  provisioner "local-exec" {
    command     = <<-EOT
      for i in $(seq 1 30); do
        if kubectl get deployment certificate-manager-cert-manager-webhook \
          -n ${kubernetes_namespace_v1.certificate[0].metadata[0].name} \
          -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q '1'; then
          echo "cert-manager webhook ready"
          exit 0
        fi
        echo "Waiting for cert-manager webhook... ($i/30)"
        sleep 10
      done
      echo "Timeout waiting for cert-manager webhook"
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


resource "kubernetes_manifest" "certificate" {
  count = var.install_certificate_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt"
    }

    spec = {
      acme = {
        email  = var.certificate_issuer_email
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = { name = "letsencrypt" }

        solvers = [{
          http01 = {
            ingress = { class = "traefik" }
          }
        }]
      }
    }
  }

  depends_on = [terraform_data.certificate_webhook_ready]
}
