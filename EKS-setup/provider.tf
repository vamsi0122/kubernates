terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.82.2"
    }
  }
  
  backend "s3" {
    bucket         = "myroboshoppractice"
    key            = "terraform/vpc"
    region         = "us-east-1"
    dynamodb_table = "myroboshoppractice" #while creating partition id should be lockid
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

