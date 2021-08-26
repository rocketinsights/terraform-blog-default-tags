terraform {
  required_version = ">= 0.12.31"
  required_providers {
    aws = {
      version = "~> 3.38.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  // Default tags: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  // AWS resource tagging: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  default_tags {
    tags = {
      owner               = "Rocket Insights"
      project             = "Project A"
      // Tagging Terraform path helps maintenance
      terraform-base-path = replace(path.cwd, "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}

// Multiple providers: https://www.terraform.io/docs/language/providers/configuration.html#alias-multiple-provider-configurations
provider "aws" {
  alias  = "alt-tags"
  region = "us-east-1"
  default_tags {
    tags = {
      modified = "Terraform"
      owner    = "Owner B"
    }
  }
}
