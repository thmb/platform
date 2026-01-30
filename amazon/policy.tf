resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name      = "${var.project_name}-cluster-role"
    Component = "platform"
  }
}


resource "aws_iam_role_policy_attachment" "cluster_repository" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "cluster" {
  name = "${var.project_name}-cluster-profile"
  role = aws_iam_role.cluster.name

  tags = {
    Name      = "${var.project_name}-cluster-profile"
    Component = "platform"
  }
}
