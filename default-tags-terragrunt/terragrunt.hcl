locals {
  aws_region = "us-east-1"
  terraform-git-repo = "terraform-blog-default-tags"
}

# Generate an AWS provider block
generate "provider" {
  # This is using the Terraform built-in override file functionality
  # https://www.terraform.io/language/files/override
  path = "terragrunt_generated_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
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
  region = "${local.aws_region}"
  // Default tags: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  // AWS resource tagging: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  default_tags {
    tags = {
      owner               = "Rocket Insights"
      project             = "Project A"
      // This tag helps AWS UI users discover what
      // Terragrunt git repo and directory to modify
      // No need for an awkward regex like in Terraform
      terragrunt-base-path = "${local.terraform-git-repo}/${path_relative_to_include()}"
    }
  }
}

// Multiple providers: https://www.terraform.io/docs/language/providers/configuration.html#alias-multiple-provider-configurations
provider "aws" {
  alias  = "alt-tags"
  region = "${local.aws_region}"
  default_tags {
    tags = {
      app-id = "Terraform Default Tags"
      owner  = "Alt Owner"
    }
  }
}
EOF
}

terraform {
  source = "./tfmodules/default-tags-main"
}
