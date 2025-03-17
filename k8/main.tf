provider "aws" {
  region = "us-east-1"  # Change if needed
}

# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get Supported Subnets for EKS (Avoids `us-east-1e`)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Filter only supported AZs
data "aws_subnet" "filtered_subnets" {
  for_each = toset(["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"])
  filter {
    name   = "availability-zone"
    values = [each.key]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Collect only the filtered subnet IDs
locals {
  eks_subnets = [for s in data.aws_subnet.filtered_subnets : s.id]
}

# Security Group (Uses Default Rules)
resource "aws_security_group" "default_sg" {
  vpc_id = data.aws_vpc.default.id
}

# EKS IAM Role
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Policies to EKS Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "practice-eks"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = local.eks_subnets  # Use filtered subnets
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Policies to Node Group Role
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create Node Group
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids    = local.eks_subnets  # Use filtered subnets
  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}

# Workstation Instance (No Key Pair)
resource "aws_instance" "workstation" {
  ami           = "ami-0b4f379183e5706b9"
  instance_type = "t3.micro"
  subnet_id     = element(local.eks_subnets, 0)  # Pick a valid subnet
  vpc_security_group_ids = [aws_security_group.default_sg.id]  # FIX: Use `vpc_security_group_ids`

  tags = {
    Name = "practice-workstation"
  }
}
