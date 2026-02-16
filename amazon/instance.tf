data "aws_ami" "system" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["${var.system_image}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


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
        "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.kubernetes_version} sh -s - --write-kubeconfig-mode 644 --tls-san ${aws_eip.cluster.public_ip}",
        "sleep 30",
        "k3s kubectl create serviceaccount terraform -n kube-system || true",
        "k3s kubectl create clusterrolebinding terraform-admin --clusterrole=cluster-admin --serviceaccount=kube-system:terraform || true"
      ]
    })
  }
}


resource "aws_key_pair" "cluster" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name      = "${var.project_name}-key"
    Component = "platform"
  }
}


resource "aws_instance" "cluster" {
  instance_type = var.instance_type
  ami           = data.aws_ami.system.id

  key_name = aws_key_pair.cluster.key_name

  iam_instance_profile = aws_iam_instance_profile.cluster.name

  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.cluster.id]

  user_data = data.cloudinit_config.cluster.rendered

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 40
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name      = "${var.project_name}-cluster"
    Component = "platform"
  }

  depends_on = [aws_eip.cluster]
}


resource "aws_eip_association" "cluster" {
  instance_id   = aws_instance.cluster.id
  allocation_id = aws_eip.cluster.id
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
  depends_on = [aws_eip_association.cluster, local_sensitive_file.ssh_key]

  triggers_replace = [aws_instance.cluster.id]

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
        if ssh $SSH_OPTS admin@${aws_eip.cluster.public_ip} \
          'sudo test -f /etc/rancher/k3s/k3s.yaml && sudo k3s kubectl get serviceaccount terraform -n kube-system' \
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
    
    CERTIFICATE=$(ssh $SSH_OPTS admin@${aws_eip.cluster.public_ip} \
      'sudo grep certificate-authority-data /etc/rancher/k3s/k3s.yaml | awk "{print \$2}"' 2>/dev/null)
    
    TOKEN=$(ssh $SSH_OPTS admin@${aws_eip.cluster.public_ip} \
      'sudo k3s kubectl create token terraform -n kube-system --duration=87600h' 2>/dev/null)
    
    cat <<JSON
{
  "host": "https://${aws_eip.cluster.public_ip}:6443",
  "certificate": "$CERTIFICATE",
  "token": "$TOKEN"
}
JSON
  EOF
  ]
}
