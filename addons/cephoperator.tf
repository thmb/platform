resource "kubernetes_namespace_v1" "objectstore" {
  count = var.install_objectstore_operator ? 1 : 0

  metadata {
    name = "rook-ceph"
  }
}


resource "helm_release" "objectstore" {
  count = var.install_objectstore_operator ? 1 : 0

  name             = "rook-ceph"
  namespace        = kubernetes_namespace_v1.objectstore[0].metadata[0].name
  create_namespace = false

  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
  version    = "1.19.2"

  timeout = 300
  atomic  = true

  values = [
    yamlencode({
      crds = {
        enabled = true
      }

      # Single-node K3S: reduce provisioner replicas
      csi = {
        # K3S kubelet path (differs from default /var/lib/kubelet)
        kubeletDirPath      = "/var/lib/rancher/k3s/agent/kubelet"
        provisionerReplicas = 1

        enableRbdDriver    = true
        enableCephfsDriver = false
        nfs = {
          enabled = false
        }
      }

      # Lean resource limits for a single dev node
      resources = {
        limits = {
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }

      # Disable monitoring (no Prometheus on dev cluster)
      monitoring = {
        enabled = false
      }
    })
  ]
}
