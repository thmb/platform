# Hetzner Cloud - K3S Single Instance

Terraform module for deploying a single-node K3S cluster on Hetzner Cloud.

## Architecture

```
                    Internet
                       │
                       ▼
              ┌────────────────┐
              │   Primary IP   │
              │   (IPv4/IPv6)  │
              └────────┬───────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
     Port 22       Port 6443      Port 80/443
      (SSH)        (K3S API)      (HTTP/HTTPS)
        │              │              │
        └──────────────┼──────────────┘
                       │
              ┌────────▼─────────┐
              │    Firewall      │
              └────────┬─────────┘
                       │
              ┌────────▼─────────┐
              │  Cloud Server    │
              │     (CX32)       │
              │   Debian 13      │
              │                  │
              │  ┌────────────┐  │
              │  │    K3S     │  │
              │  │  v1.35.1   │  │
              │  └────────────┘  │
              └──────────────────┘
                   80GB NVMe
```

## Components

| Resource | Type | Purpose |
|----------|------|---------|
| **Compute** | `cx32` (4 vCPU shared, 8GB RAM) | K3S server node |
| **Storage** | `80GB NVMe` local SSD | Root volume |
| **Network** | Primary IP (IPv4 + IPv6) | Static IP addresses |
| **Firewall** | Hetzner Cloud Firewall | SSH, HTTP/S, K3S API access rules |
| **K3S** | `v1.35.1+k3s1` | Kubernetes distribution |

## Usage

```bash
# Configure credentials
export HCLOUD_TOKEN="..."

# Create tfvars
cat > terraform.tfvars <<EOF
ssh_public_key  = "ssh-ed25519 AAAA..."
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
<private-key-content-here>
-----END OPENSSH PRIVATE KEY-----
cidr_blocks     = ["YOUR_IP/32", "::/0"]
EOF

# Deploy
terraform init
terraform apply

# Access
ssh -i .ssh-key root@$(terraform output -raw public_ip)
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `project_name` | Project name for resource tagging | `thmb` |
| `default_location` | Hetzner Cloud location | `nbg1` (Nuremberg) |
| `instance_type` | Server type | `cx32` |
| `system_image` | OS image name | `debian-13` |
| `kubernetes_version` | K3S version | `v1.35.1+k3s1` |
| `cidr_blocks` | CIDR blocks allowed for SSH and K3S API | `["0.0.0.0/0", "::/0"]` |
| `ssh_public_key` | SSH public key content | *required* |
| `ssh_private_key` | SSH private key content | *required* |

## Outputs

| Name | Description |
|------|-------------|
| `server_id` | Hetzner Cloud server ID |
| `public_ip` | Primary IPv4 address |
| `kubernetes_host` | K3S API endpoint |
| `kubernetes_token` | Kubernetes bearer token |
| `kubernetes_certificate` | K3S CA certificate (base64) |

## Cost Estimate

- **CX32**: ~€8.21/month (~$8.90/month)
- **80GB NVMe**: Included
- **Primary IP**: €0.63/month (~$0.68/month)
- **Traffic**: 20TB included
- **Total**: ~€8.84/month (~$9.58/month)

## Notes

- K3S installs automatically via cloud-init
- Cluster credentials extracted via SSH after bootstrap
- Default user: `root` (Hetzner default)
- Firewall restricts access to `cidr_blocks`
- IPv6 enabled by default
