# Cluster Addons

Terraform module that installs essential Kubernetes operators via Helm onto a single-node K3S cluster.
All three addons are defined in `addons.tf` and can be toggled independently.

## Addons

| Addon | Chart | Namespace | Purpose |
|-------|-------|-----------|---------|
| **Cert-Manager** | `jetstack/cert-manager v1.19.3` | `cert-manager` | TLS certificate automation via Let's Encrypt |
| **CloudNativePG** | `cnpg/cloudnative-pg v0.27.1` | `cnpg-operator` | PostgreSQL Cloud Native operator |
| **Rook-Ceph** | `rook-release/rook-ceph v1.19.2` | `rook-operator` | Ceph storage operator (block, filesystem, object) |

## Architecture

```
┌─────────────────────────────────────────────┐
│                K3S Cluster                  │
│                                             │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │ cert-manager │  │ ClusterIssuer        │ │
│  │  (webhook)   │  │ (letsencrypt / ACME) │ │
│  └──────────────┘  └──────────────────────┘ │
│                                             │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │ CNPG         │  │ Rook-Ceph            │ │
│  │ operator     │  │ operator             │ │
│  └──────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────┘
```

The Rook-Ceph operator is configured for K3S with:
- `kubeletDirPath = /var/lib/rancher/k3s/agent/kubelet`
- `provisionerReplicas = 1` (single-node)
- CephFS and NFS drivers disabled by default

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
| `install_cert_manager` | Deploy cert-manager + ClusterIssuer | `true` |
| `cert_manager_email` | Let's Encrypt account email | `admin@thau.tech` |
| `install_cnpg_operator` | Deploy CloudNativePG operator | `true` |
| `install_rook_operator` | Deploy Rook-Ceph operator | `true` |

## Verify

```bash
kubectl get pods -n cert-manager
kubectl get pods -n cnpg-operator
kubectl get pods -n rook-operator
kubectl get clusterissuer letsencrypt
```

## Notes

- All Helm releases use `atomic = true` for automatic rollback on failure
- cert-manager webhook readiness is polled before creating the `ClusterIssuer`
- Each addon is independently toggleable without affecting the others
- The Ceph cluster itself is provisioned separately in `storage/ceph`
- The CNPG cluster itself is provisioned separately in `storage/cnpg`
