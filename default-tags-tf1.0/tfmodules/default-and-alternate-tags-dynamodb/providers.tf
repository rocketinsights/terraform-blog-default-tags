# This is the minimum Terraform versions that this module was tested against
terraform {
  required_version = "~> 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.69.0"
      // Multiple provider in >= TF 0.13 modules documentation
      // https://www.terraform.io/language/providers/configuration#alias-multiple-provider-configurations
      configuration_aliases = [ aws.alt-tags ]
    }
  }
}
