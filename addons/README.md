# Cluster Addons

Terraform module that installs essential Kubernetes operators via Helm.

## Addons

| Addon | Chart | Namespace | Purpose |
|-------|-------|-----------|---------|
| **cert-manager** | `jetstack/cert-manager` | `certificate-system` | TLS certificate automation via Let's Encrypt |
| **CloudNativePG** | `cnpg/cloudnative-pg` | `database-system` | PostgreSQL operator |
| **SeaweedFS** | `seaweedfs/seaweedfs-operator` | `objectstore-system` | Distributed object storage operator |

Each addon can be toggled independently via `install_*` variables.

## Architecture

```
┌─────────────────────────────────────────┐
│              K3S Cluster                │
│                                         │
│  ┌──────────────┐ ┌──────────────────┐  │
│  │ cert-manager │ │ ClusterIssuer    │  │
│  │  (webhook)   │ │ (letsencrypt)    │  │
│  └──────────────┘ └──────────────────┘  │
│                                         │
│  ┌──────────────┐ ┌──────────────────┐  │
│  │   CNPG       │ │   SeaweedFS      │  │
│  │  operator    │ │   operator       │  │
│  └──────────────┘ └──────────────────┘  │
└─────────────────────────────────────────┘
```

## Usage

```bash
terraform init
terraform apply \
  -var="kubernetes_host=https://1.2.3.4:6443" \
  -var="kubernetes_token=..." \
  -var="kubernetes_certificate=..."
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `kubernetes_host` | API server URL | `http://localhost:6443` |
| `kubernetes_token` | API server bearer token | *required* |
| `kubernetes_certificate` | API server CA certificate (base64) | *required* |
| `install_certificate_manager` | Deploy cert-manager | `true` |
| `certificate_chart_version` | cert-manager chart version | `v1.19.3` |
| `certificate_issuer_email` | Let's Encrypt email | `admin@thau.tech` |
| `install_database_operator` | Deploy CloudNativePG | `true` |
| `database_chart_version` | CNPG chart version | `0.27.1` |
| `install_objectstore_operator` | Deploy SeaweedFS | `true` |
| `objectstore_chart_version` | SeaweedFS chart version | `0.1.13` |

## Verify

```bash
kubectl get pods -n certificate-system
kubectl get pods -n database-system
kubectl get pods -n objectstore-system
kubectl get clusterissuer letsencrypt
```

## Notes

- All Helm releases use `atomic = true` for automatic rollback on failure
- cert-manager webhook readiness is verified before creating the ClusterIssuer
- Each addon is independently toggleable without affecting the others
