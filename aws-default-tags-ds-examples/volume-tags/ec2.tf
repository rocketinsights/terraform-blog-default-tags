# In a professional setting, a hard-pin of terraform versions ensures all
# team members use the same version, reducing state conflict
terraform {
  required_version = "1.1"
  required_providers {
    aws = {
      version = "3.69.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  // Default tags: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  // AWS resource tagging: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

# Retrieve the AWS provider default tags for programmatic use
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags
data "aws_default_tags" "provider" {}

resource "aws_instance" "default-tags-ec2" {
  ami = data.aws_ami.default-tags-ami.id
  instance_type = "t2.micro"

  # Assigns the default tags to volumes attached to this EC2 instance
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#volume_tags
  volume_tags = data.aws_default_tags.provider.tags
}

data "aws_ami" "default-tags-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}