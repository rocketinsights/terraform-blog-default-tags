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
      owner               = "Rocket Insights"
      project             = "Project A"
      // This regex results in the terraform git repo name and any sub-directories.
      // For this repo, terraform-base-path is terraform-blog-default-tags/default-tags
      // This tag helps AWS UI users discover what Terraform git repo and directory to modify
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
      app-id = "Terraform Default Tags"
      owner  = "Alt Owner"
    }
  }
}
