# ==============================================================================
# CERT-MANAGER
# ==============================================================================

resource "kubernetes_namespace_v1" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0

  metadata { name = "cert-manager" }
}


resource "helm_release" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0

  name             = "cert-manager"
  namespace        = kubernetes_namespace_v1.cert_manager[0].metadata[0].name
  create_namespace = false

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.19.3"

  timeout = 300
  atomic  = true
  wait    = true

  values = [
    yamlencode({
      crds            = { enabled = true }
      startupapicheck = { enabled = false }

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


resource "terraform_data" "cert_manager_ready" {
  count = var.install_cert_manager ? 1 : 0

  triggers_replace = [helm_release.cert_manager[0].metadata[0].revision]

  provisioner "local-exec" {
    command     = <<-EOT
      i=0
      while [ $i -lt 30 ]; do
        i=$((i + 1))
        if kubectl get deployment ${helm_release.cert_manager[0].name}-cert-manager-webhook \
          -n ${kubernetes_namespace_v1.cert_manager[0].metadata[0].name} \
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


resource "kubernetes_manifest" "cert_manager_issuer" {
  count = var.install_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = { name = "letsencrypt" }

    spec = {
      acme = {
        email  = var.cert_manager_email
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

  depends_on = [terraform_data.cert_manager_ready]
}


# ==============================================================================
# CLOUD NATIVE POSTGRESQL OPERATOR
# ==============================================================================

resource "kubernetes_namespace_v1" "cnpg_operator" {
  count = var.install_cnpg_operator ? 1 : 0

  metadata { name = "cnpg-operator" }
}


resource "helm_release" "cnpg_operator" {
  count = var.install_cnpg_operator ? 1 : 0

  name             = "cloudnative-pg"
  namespace        = kubernetes_namespace_v1.cnpg_operator[0].metadata[0].name
  create_namespace = false

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = "0.27.1"

  timeout = 300
  atomic  = true

  values = [
    yamlencode({
      crds = { create = true }
    })
  ]
}


# ==============================================================================
# ROOK-CEPH OPERATOR
# ==============================================================================

resource "kubernetes_namespace_v1" "rook_operator" {
  count = var.install_rook_operator ? 1 : 0

  metadata { name = "rook-operator" }
}


resource "helm_release" "rook_operator" {
  count = var.install_rook_operator ? 1 : 0

  name             = "rook-ceph"
  namespace        = kubernetes_namespace_v1.rook_operator[0].metadata[0].name
  create_namespace = false

  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
  version    = "1.19.2"

  timeout = 300
  atomic  = true

  values = [
    yamlencode({
      crds = { enabled = true }

      csi = {
        kubeletDirPath      = "/var/lib/rancher/k3s/agent/kubelet" # k3s kubelet path
        provisionerReplicas = 1                                    # reduce provisioner replicas

        enableRbdDriver    = true
        enableCephfsDriver = false
        nfs                = { enabled = false }
      }

      resources = { # lean resource limits
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "100m", memory = "512Mi" }
      }

      monitoring = { enabled = false } # no prometheus
    })
  ]
}
