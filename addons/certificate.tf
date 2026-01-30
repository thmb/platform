resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.certmanager_version

  set = [{
    name  = "crds.enabled"
    value = "true"
  }]
}


resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = { name = "letsencrypt" }

    spec = {
      acme = {
        email  = var.certmanager_email
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

  depends_on = [helm_release.cert_manager]
}
