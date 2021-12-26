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

resource "aws_autoscaling_group" "default-tags-asg" {
  name = "default-tags-asg"

  tag {
    key                 = "Name"
    value               = "default-tags-asg-ec2"
    propagate_at_launch = true
  }
  # Loops through the AWS provider default_tags to generate
  # multiple aws_autoscaling_group specific propagate_at_launch tag.
  # Any EC2 instances launched by this ASG will have these tags
  # automatically attached.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#propagate_at_launch
  dynamic "tag" {
    for_each = data.aws_default_tags.provider.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  max_size           = 0
  min_size           = 0
  availability_zones = ["us-east-1a"]
  launch_template {
    id      = aws_launch_template.default-tags-lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "default-tags-lt" {
  name          = "default-tags-lt"
  instance_type = "t2.micro"
  image_id      = data.aws_ami.default-tags-ami.id

  # The EC2 instances created by this launch template
  # will have these tags automatically attached
  tag_specifications {
    resource_type = "instance"
    tags          = data.aws_default_tags.provider.tags
  }

  # The EBS volume of the EC2 instances created by this launch template
  # will have these tags automatically attached
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name = "default-tags-lt-volume"
      },
      data.aws_default_tags.provider.tags
    )
  }
}

data "aws_ami" "default-tags-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}