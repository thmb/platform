resource "kubernetes_namespace_v1" "objectstore" {
  count = var.install_objectstore_operator ? 1 : 0

  metadata {
    name = "objectstore-system"
  }
}


resource "helm_release" "objectstore" {
  count = var.install_objectstore_operator ? 1 : 0

  name             = "objectstore-operator"
  namespace        = kubernetes_namespace_v1.objectstore[0].metadata[0].name
  create_namespace = false

  repository = "https://seaweedfs.github.io/seaweedfs-operator"
  chart      = "seaweedfs-operator"
  version    = var.objectstore_chart_version

  timeout = 300
  atomic  = true


  values = [
    yamlencode({
      webhook = {
        enabled = false
      }
    })
  ]
}
