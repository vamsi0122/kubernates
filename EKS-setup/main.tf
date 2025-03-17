resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "free-tier-eks"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = slice(data.aws_subnets.default.ids, 0, 2) # Select the first two valid subnets
  }

  depends_on = [aws_iam_role.eks_role]
}
