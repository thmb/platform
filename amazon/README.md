# AWS - K3S Single Instance

Terraform module for deploying a single-node K3S cluster on AWS EC2.

# AWS - K3S Single Instance

Terraform module for deploying a single-node K3S cluster on AWS EC2.

## Architecture

```
                    Internet
                       │
                       ▼
              ┌────────────────┐
              │   Elastic IP   │
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
              │  Security Group  │
              └────────┬─────────┘
                       │
              ┌────────▼─────────┐
              │   EC2 Instance   │
              │   (t3a.large)    │
              │   Debian 13      │
              │                  │
              │  ┌────────────┐  │
              │  │    K3S     │  │
              │  │  v1.35.1   │  │
              │  └────────────┘  │
              └──────────────────┘
                   40GB gp3
```

## Components

| Resource | Type | Purpose |
|----------|------|---------|
| **Compute** | `t3a.large` (2 vCPU, 8GB RAM) | K3S server node |
| **Storage** | `gp3` 40GB encrypted | Root volume |
| **Network** | Elastic IP + Security Group | Static IP with SSH, HTTP/S, K3S API access |
| **IAM** | Instance profile | ECR read-only access |
| **K3S** | `v1.35.1+k3s1` | Kubernetes distribution |

## Usage

```bash
# Configure credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

# Create tfvars
cat > terraform.tfvars <<EOF
ssh_public_key  = "ssh-ed25519 AAAA..."
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
<private-key-content-here>
-----END OPENSSH PRIVATE KEY-----
cidr_blocks     = ["YOUR_IP/32"]
EOF

# Deploy
terraform init
terraform apply

# Access
ssh -i .ssh-key admin@$(terraform output -raw public_ip)
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `project_name` | Project name for resource tagging | `thmb` |
| `default_location` | AWS region | `sa-east-1` |
| `instance_type` | EC2 instance type | `t3a.large` |
| `system_image` | OS image name pattern | `debian-13-backports` |
| `kubernetes_version` | K3S version | `v1.35.1+k3s1` |
| `cidr_blocks` | CIDR blocks allowed for SSH and K3S API | `["0.0.0.0/0"]` |
| `ssh_public_key` | SSH public key content | *required* |
| `ssh_private_key` | SSH private key content | *required* |

## Outputs

| Name | Description |
|------|-------------|
| `public_ip` | Elastic IP address |
| `kubernetes_host` | K3S API endpoint |
| `kubernetes_token` | Kubernetes bearer token |
| `kubernetes_certificate` | K3S CA certificate (base64) |

## Cost Estimate

- **t3a.large**: ~$55/month
- **EBS gp3 40GB**: ~$3.20/month
- **Elastic IP**: Free (while attached)
- **Total**: ~$58/month

## Notes

- K3S installs automatically via cloud-init
- Cluster credentials extracted via SSH after bootstrap
- Default user: `admin` (Debian AMI default)
- Firewall restricts access to `cidr_blocks`
