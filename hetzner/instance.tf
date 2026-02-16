data "cloudinit_config" "cluster" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      package_update  = true
      package_upgrade = true

      packages = [
        "curl",
        "ca-certificates",
      ]

      runcmd = [
        "LATEST=$(curl -s https://api.github.com/repos/k3s-io/k3s/releases/latest | sed -n 's/.*\"tag_name\": \"\\([^\"]*\\)\".*/\\1/p')",
        "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$LATEST sh -s - --write-kubeconfig-mode 644 --tls-san ${hcloud_primary_ip.cluster.ip_address} --tls-san 127.0.0.1 --tls-san localhost",
        "sleep 30",
        "k3s kubectl create serviceaccount terraform -n kube-system || true",
        "k3s kubectl create clusterrolebinding terraform-admin --clusterrole=cluster-admin --serviceaccount=kube-system:terraform || true"
      ]
    })
  }
}


resource "hcloud_ssh_key" "cluster" {
  name       = "${var.project_name}-key"
  public_key = var.ssh_public_key

  labels = {
    Name      = "${var.project_name}-key"
    Component = "platform"
  }
}


resource "hcloud_server" "cluster" {
  name        = "${var.project_name}-cluster"
  server_type = var.server_type
  image       = var.image
  location    = var.location

  ssh_keys     = [hcloud_ssh_key.cluster.id]
  firewall_ids = [hcloud_firewall.cluster.id]

  user_data = data.cloudinit_config.cluster.rendered

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.cluster.id
    ipv6_enabled = true
  }

  labels = {
    Name      = "${var.project_name}-cluster"
    Component = "platform"
  }
}

# ==============================================================================
# CREDENTIALS
# ==============================================================================

resource "local_sensitive_file" "ssh_key" {
  content         = var.ssh_private_key
  filename        = "${path.module}/.ssh-key"
  file_permission = "0600"
}


resource "terraform_data" "wait_for_cluster" {
  depends_on = [hcloud_server.cluster, local_sensitive_file.ssh_key]

  triggers_replace = [hcloud_server.cluster.id]

  provisioner "local-exec" {
    command = <<-EOF
      set -e
      
      unset SSH_AUTH_SOCK SSH_AGENT_PID
      
      SSH_OPTS="-i ${local_sensitive_file.ssh_key.filename} \
        -o IdentitiesOnly=yes \
        -o IdentityAgent=none \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5"
      
      echo "Waiting for K3S cluster..."
      counter=1
      while [ $counter -le 60 ]; do
        if ssh $SSH_OPTS root@${hcloud_primary_ip.cluster.ip_address} \
          'test -f /etc/rancher/k3s/k3s.yaml && k3s kubectl get serviceaccount terraform -n kube-system' \
          >/dev/null 2>&1; then
          echo "Cluster ready!"
          exit 0
        fi
        
        if [ $counter -eq 60 ]; then
          echo "Timeout waiting for cluster"
          exit 1
        fi
        
        counter=$((counter + 1))
        sleep 5
      done
    EOF
  }
}

data "external" "cluster_config" {
  depends_on = [terraform_data.wait_for_cluster]

  program = ["bash", "-c", <<-EOF
    set -e
    
    unset SSH_AUTH_SOCK SSH_AGENT_PID
    
    SSH_OPTS="-i ${local_sensitive_file.ssh_key.filename} \
      -o IdentitiesOnly=yes \
      -o IdentityAgent=none \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=5"
    
    CERTIFICATE=$(ssh $SSH_OPTS root@${hcloud_primary_ip.cluster.ip_address} \
      'grep certificate-authority-data /etc/rancher/k3s/k3s.yaml | awk "{print \$2}"' 2>/dev/null)
    
    TOKEN=$(ssh $SSH_OPTS root@${hcloud_primary_ip.cluster.ip_address} \
      'k3s kubectl create token terraform -n kube-system --duration=87600h' 2>/dev/null)
    
    cat <<JSON
{
  "host": "https://${hcloud_primary_ip.cluster.ip_address}:6443",
  "certificate": "$CERTIFICATE",
  "token": "$TOKEN"
}
JSON
  EOF
  ]
}
