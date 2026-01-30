resource "github_actions_secret" "kubernetes_host" {
  for_each        = toset(var.target_repositories)
  repository      = each.value
  secret_name     = "<SECRET_NAME>"
  plaintext_value = "<secret_value>"
}
