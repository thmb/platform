# PLATFORM

Single-node K3S Kubernetes cluster on AWS EC2.

## Folder Structure

```
platform/
├── .github/
│   └── workflows/
│       └── main.yaml          # GitHub Actions CI/CD
├── addons/                    # Kubernetes addons (cert-manager, etc.)
│   ├── certificate.tf
│   ├── variables.tf
│   └── versions.tf
├── amazon/                    # AWS infrastructure (EC2, VPC, IAM)
│   ├── amazon.sh              # IAM user bootstrap script
│   ├── instance.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── policy.tf
│   ├── variables.tf
│   └── versions.tf
├── cloudflare/                # Cloudflare DNS and R2 storage
│   ├── bucket.tf
│   ├── record.tf
│   ├── variables.tf
│   └── versions.tf
├── github/                    # GitHub secrets management
│   ├── secret.tf
│   ├── variables.tf
│   └── versions.tf
├── hetzner/                   # Hetzner Cloud (alternative provider)
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
├── cluster.sh                 # K3S installation script
├── config.yaml                # K3S server configuration
├── README.md
└── terraform.tfvars.example
```

## Architecture

```
┌───────────────────────────────────────────────────────────┐
│                        INTERNET                           │
└────────────────────────────┬──────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Elastic IP    │
                    │  (Public)      │
                    └────────┬───────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
        Port 22         Port 80/443        Port 6443
         (SSH)          (HTTP/HTTPS)       (K3S API)
           │                 │                 │
           └─────────────────┼─────────────────┘
                             │
           ┌─────────────────▼──────────────────┐
           │      AWS VPC (10.0.0.0/16)         │
           │  ┌──────────────────────────────┐  │
           │  │  Public Subnet (10.0.1.0/24) │  │
           │  │  ┌────────────────────────┐  │  │
           │  │  │  EC2 Instance          │  │  │
           │  │  │  t3a.large (amd64)     │  │  │
           │  │  │  Debian 13 (backports) │  │  │
           │  │  │                        │  │  │
           │  │  │  ┌──────────────────┐  │  │  │
           │  │  │  │  K3S (latest)    │  │  │  │
           │  │  │  │  + Traefik       │  │  │  │
           │  │  │  └──────────────────┘  │  │  │
           │  │  └────────────────────────┘  │  │
           │  └──────────────────────────────┘  │
           │                                    │
           │  Internet Gateway                  │
           └────────────────────────────────────┘
```

## Infrastructure Components

- **VPC**: Isolated network (10.0.0.0/16)
- **Public Subnet**: Single subnet for K3S instance
- **EC2 Instance**: t3a.large (2 vCPU, 8 GB RAM, 32 GB gp3)
- **Elastic IP**: Static public IP address
- **Security Group**: SSH (22), HTTP (80), HTTPS (443), K3S API (6443)
- **K3S**: Latest stable Kubernetes with Traefik ingress controller
- **Auto-generated SSH Key**: ED25519 key pair stored in GitHub Secrets

## Setup Instructions

### 1. Prerequisites

- Terraform >= 1.14.0
- AWS CLI with credentials configured
- GitHub CLI (for retrieving SSH key)

### 2. Setup Cloudflare API Token

Follow [CLOUDFLARE_SETUP.md](CLOUDFLARE_SETUP.md) to create and configure your Cloudflare API token.

### 3. Initialize Terraform

```bash
cd amazon  # or addons, cloudflare, github, hetzner
terraform init
```

### 4. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
# IMPORTANT: Add your Cloudflare API token
```

### 5. Review Plan

```bash
terraform plan
```

### 6. Deploy Infrastructure

```bash
terraform apply
```

This will provision:

- VPC and networking
- Security groups (SSH, HTTP, HTTPS, K3S API)
- EC2 instance with K3S installed
- Elastic IP (public)
- Auto-generated SSH key pair (stored in GitHub Secrets)

## SSH Access to EC2 Instance

The SSH key pair is auto-generated during Terraform provisioning and stored in GitHub Secrets.

### Using GitHub CLI

```bash
# Install GitHub CLI (if not installed)
# macOS: brew install gh
# Linux: sudo apt install gh

# Authenticate
gh auth login

# Get the SSH key
gh secret get SSH_PRIVATE_KEY -R <owner>/<repo> > ~/.ssh/platform-deploy
chmod 600 ~/.ssh/platform-deploy

# Get the EC2 IP address
terraform output -raw public_ip

# Connect
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)
```

### Notes

- The SSH key pair is stored in GitHub Secrets
- The private key is securely stored and never committed to the repository

## Managing the Platform

### Access K3S

```bash
# SSH into the instance (from amazon/ directory)
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Once connected, use kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A
```

### Check K3S Status

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Check K3S service status
sudo systemctl status k3s

# Get nodes
sudo k3s kubectl get nodes
```

### View Logs

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# K3S service logs
sudo journalctl -u k3s -n 100

# User data logs
sudo cat /var/log/user-data.log
```

### Restart K3S

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Restart service
sudo systemctl restart k3s
```

## Deploying Applications

### Example: Deploy Nginx

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Set kubeconfig and deploy
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo k3s kubectl create deployment nginx --image=nginx
sudo k3s kubectl expose deployment nginx --port=80 --type=LoadBalancer
sudo k3s kubectl get svc nginx
```

Access at `http://<PUBLIC_IP>` (Traefik will route the traffic)

## Cleanup

```bash
terraform destroy
```

This will remove all AWS resources including the instance, VPC, and Elastic IP.

## Cost Estimate

- **t3a.large**: ~$0.0752/hour (~$54.95/month)
- **EBS gp3 32GB**: ~$2.56/month
- **Elastic IP**: Free while attached
- **Total**: ~$57.51/month

## Security Recommendations

1. **Restrict SSH Access**: Update `ssh_cidrs` in `terraform.tfvars` to trusted IPs only
2. **Restrict K3S API Access**: Use the same `ssh_cidrs` to limit K3S API access
3. **Enable AWS Secrets Manager**: Store sensitive credentials
4. **Enable CloudWatch**: Monitor logs and metrics
5. **Regular Updates**: Keep K3S and Debian updated
6. **Backup**: Regular snapshots of EBS volume
7. **Rotate SSH Keys**: Recreate infrastructure to generate new keys

## Troubleshooting

### K3S not starting

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Check logs
sudo journalctl -u k3s -n 100
sudo cat /var/log/user-data.log
```

### Can't connect via SSH

```bash
# Verify you have the SSH key
ls -la ~/.ssh/platform-deploy

# Get the key from GitHub if missing
gh secret get SSH_PRIVATE_KEY -R <owner>/<repo> > ~/.ssh/platform-deploy
chmod 600 ~/.ssh/platform-deploy

# Check security group allows your IP
# Update ssh_cidrs in terraform.tfvars if needed
```

### Can't connect to K3S API

K3S API (port 6443) is restricted by `ssh_cidr_blocks`. Ensure your IP is included:

```bash
# SSH into instance
ssh -i ~/.ssh/platform-deploy admin@$(terraform output -raw public_ip)

# Use kubectl locally on the instance
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get nodes
```

### Instance not accessible

Verify Elastic IP is attached:

```bash
aws ec2 describe-addresses
```

## DNS (Cloudflare)

This guide explains how to create and configure Cloudflare API tokens for Terraform.

## Creating a Cloudflare API Token

### 1. Log into Cloudflare Dashboard

Visit [dash.cloudflare.com](https://dash.cloudflare.com) and log in to your account.

### 2. Navigate to API Tokens

1. Click on your profile icon (top right)
2. Select **"My Profile"**
3. Go to **"API Tokens"** tab
4. Click **"Create Token"**

### 3. Create Custom Token

For Terraform, you'll need a token with DNS and Zone permissions:

1. Click **"Create Custom Token"**
2. Configure the token:

   **Token name**: `terraform-raio-energia`
   
   **Permissions**:
   - Zone → Zone → Read
   - Zone → DNS → Edit
   
   **Zone Resources**:
   - Include → Specific zone → `raioenergia.com.br`
   
   **TTL**: Leave blank for no expiration (or set as needed)

3. Click **"Continue to summary"**
4. Review permissions
5. Click **"Create Token"**

### 4. Copy Your Token

⚠️ **Important**: The token will only be shown once. Copy it immediately!

```
Example token format: 
8M7wS6hCpXVc-DoRnPFW-nVQUq_xr76kR0Zp5xSW
```

## Configuring Terraform

### Option 1: Using terraform.tfvars (Recommended)

1. Copy the example file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and add your token:
   ```hcl
   cloudflare_token = "8M7wS6hCpXVc-DoRnPFW-nVQUq_xr76kR0Zp5xSW"
   ```

3. Ensure `.gitignore` includes `terraform.tfvars`:
   ```bash
   grep terraform.tfvars .gitignore
   ```

### Option 2: Using Environment Variables

Set the environment variable before running Terraform:

```bash
export CLOUDFLARE_TOKEN="8M7wS6hCpXVc-DoRnPFW-nVQUq_xr76kR0Zp5xSW"
terraform plan
```

For persistent configuration, add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
echo 'export CLOUDFLARE_TOKEN="your-token-here"' >> ~/.bashrc
source ~/.bashrc
```

## Verifying Your Token

Test the token works before using it in Terraform:

```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

Expected response:
```json
{
  "success": true,
  "errors": [],
  "messages": [],
  "result": {
    "id": "...",
    "status": "active"
  }
}
```

## Additional Resources

- [Cloudflare API Tokens Documentation](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
- [Terraform Cloudflare Provider Docs](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare API Reference](https://developers.cloudflare.com/api/)
