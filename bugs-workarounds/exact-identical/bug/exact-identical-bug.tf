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

resource "aws_dynamodb_table" "exact-identical-bug" {
  name         = "exact-identical-bug"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }

  # The resource tags are exactly identical to the AWS provider default_tags.
  # This causes the exception
  #    Error: "tags" are identical to those in the "default_tags" configuration block of the provider:
  #    please de-duplicate and try again
  # To fix, just delete the resource tags.
  tags = {
    owner   = "Rocket Insights"
    project = "Project A"
  }
}
