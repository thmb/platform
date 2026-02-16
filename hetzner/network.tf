resource "hcloud_primary_ip" "cluster" {
  name          = "${var.project_name}-ip"
  location      = var.default_location
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false

  labels = {
    Name      = "${var.project_name}-ip"
    Component = "platform"
  }
}


resource "hcloud_firewall" "cluster" {
  name = "${var.project_name}-firewall"

  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.cidr_blocks
  }

  rule {
    description = "HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "K3S API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = var.cidr_blocks
  }

  labels = {
    Name      = "${var.project_name}-firewall"
    Component = "platform"
  }
}
