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
      owner       = "Rocket Insights"
      project     = "Project A"
      environment = "dev"  # Change dev to prod to add the prod DynamoDB
    }
  }
}

# Access individual default_tags via the data source
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags
data "aws_default_tags" "provider" {}

resource "aws_dynamodb_table" "prod-only" {
  # Only create this DynamoDB table if the
  # `environment` default tag value is `prod`
  count        = data.aws_default_tags.provider.tags.environment == "prod" ? 1 : 0
  name         = "default-tags-prod-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}
