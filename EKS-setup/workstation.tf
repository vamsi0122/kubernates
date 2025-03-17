resource "aws_instance" "workstation" {
  ami                    = "ami-0b4f379183e5706b9"  # Replace with your own AMI ID
  instance_type          = "t3.micro"
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  associate_public_ip_address = true

  security_groups = [aws_security_group.workstation_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y unzip jq git aws-cli

    # Install Terraform
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip terraform_1.6.0_linux_amd64.zip
    sudo mv terraform /usr/local/bin/

    # Install kubectl
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.0/2023-06-28/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    # Configure kubectl for EKS
    aws eks update-kubeconfig --region us-east-1 --name free-tier-eks
  EOF

  tags = {
    Name = "eks-workstation"
  }

  depends_on = [aws_security_group.workstation_sg]
}
