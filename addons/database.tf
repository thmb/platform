resource "kubernetes_namespace_v1" "database" {
  count = var.install_database_operator ? 1 : 0

  metadata {
    name = "database-system"
  }
}


resource "helm_release" "database" {
  count = var.install_database_operator ? 1 : 0

  name             = "database-operator"
  namespace        = kubernetes_namespace_v1.database[0].metadata[0].name
  create_namespace = false

  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.database_chart_version

  timeout = 300
  atomic  = true


  values = [
    yamlencode({
      crds = {
        create = true
      }
    })
  ]
}
