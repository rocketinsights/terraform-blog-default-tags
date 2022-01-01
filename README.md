## Best Practices for Terraform AWS Tags

Rocket Insights [blog article here](https://blog.rocketinsights.com/best-practices-for-terraform-aws-tags/)

_Update Jan 1, 2022: Thank you for making this blog post so popular. 
It is a first page Google search result for [`aws terraform tags`](https://www.google.com/search?q=aws+terraform+tags)  ._

_Originally we coded the default tags examples for [Terraform 0.12](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/default-tags) . 
We updated the example code for [Terraform 1.0](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/default-tags-tf1.0) and 
[Terragrunt](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/default-tags-terragrunt)._

_I wrote a [follow-up article](README-part2.md) about solutions to bugs and traps when using Terraform AWS tags
in production._

[AWS tags](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) are key-value labels you can assign to AWS resources 
that give extra information about it. 

Rocket Insights DevOps practice recommends the following AWS tags best practices:
* Define [an explicit ruleset](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/welcome.html) for tag key naming and stick with it.

    Inconsistent tags keys such as "appid", "Application ID", and "App_ID" are frustrating to use.

* Strive for more tags, not less. Tag all AWS resources.

    The minimum Rocket Insights recommended set of tags are

    **Name**: human-readable resource name. Note that the AWS Console UI displays the case-sensitive "Name" tag.

    **app-id**: the application using the resource

    **app-role**: the resource's technical function, e.g. webserver, database

    **app-purpose**: the resource's business purpose, e.g. "frontend ui", "payment processor"

    **environment**: dev, test, or prod

    **project**: what projects use the resource

    **owner**: who to contact about the resource

    **cost-center**: who to bill for the resource usage

    **automation-exclude**: a true/false value for automation to not modify the resource

    **pii**: a true/false value if the resource stores personal identifiable information

* Tag all Terraform created AWS resources with code path info. 

  Tagging all AWS resources with the Terraform base and module path results in easier infrastructure maintenance.

Starting with [Terraform](https://www.terraform.io/) 0.12.31 and [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) v3.38.0, 
HashiCorp added the default tags feature.
You can now **configure AWS tags in one place** and **automatically apply them to all AWS resources**. You no longer have to manually 
add `tags` blocks to each individual Terraform AWS resource. 

This Terraform AWS default tags tutorial demonstrates for both Terraform resources and modules:
* Basic usage
* Providing alternate default tags
* Adding and overriding tags to the default

For the full Terraform code, please visit the Rocket Insights [Github repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/default-tags).

For prettier formatting, please visit the Rocket Insights [blog](https://blog.rocketinsights.com/best-practices-for-terraform-aws-tags/).

### Basic Usage

The default tags are defined in the AWS provider section. It automatically applies
to all AWS resources

```terraform
locals {
  // Change the local variable to match the git repo name
  terraform-git-repo = "terraform-blog-default-tags"
}

provider "aws" {
  region = "us-east-1"
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

resource "aws_dynamodb_table" "default-tags-basic" {
  name     = "default-tags-basic"
  .......
}

``` 
The final tags for `aws_dynamodb_table.default-tags-basic` are

```
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```
### Alternate Default Tags
If an AWS resource requires alternate default tags, define an alternate AWS provider with new default tags.

```terraform
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

resource "aws_dynamodb_table" "default-tags-alternate" {
  provider = aws.alt-tags
  name     = "default-tags-alternate"
  ........
}
```
The final tags for `aws_dynamodb_table.default-tags-alternate` are
```
"app-id" = "Terraform Default Tags"
"owner"  = "Alt Owner"
```

### Add and Override Default Tags
If an AWS resource requires more tags in addition to the default tags, simply add the tag to the
built-in resource `tags` block.

If an AWS resource requires to override a default tag, define a tag with the same key in the `tags`
block

```terraform
locals {
  terraform-git-repo = "terraform-blog-default-tags"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner               = "Rocket Insights"
      project             = "Project A"
      terraform-base-path = replace(path.cwd, "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}

resource "aws_dynamodb_table" "default-tags-add" {
  name     = "default-tags-add"
  .......
  
  tags = {
    cost-center = "Rocket Insights Billing"
    project     = "Project Override"
  }
}

```  
The final tags for `aws_dynamodb_table.default-tags-add` are

```
"cost-center"         = "Rocket Insights Billing"
"owner"               = "Rocket Insights"
"project"             = "Project Override"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

### Modules Basic Usage
The AWS default tags apply to existing Terraform AWS modules without any changes needed.

```terraform
locals {
  terraform-git-repo = "terraform-blog-default-tags"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner    = "Rocket Insights"
      project  = "Project A"
      terraform-base-path = replace(path.cwd,
      "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}

module "default-tags-dynamodb" {
  source = "./tfmodules/default-tags-dynamodb"
}
```
The final tags for `module.default-tags-dynamodb.aws_dynamodb_table.default-tags-module` are
```
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

### Modules and Alternate Tags
If an AWS module requires alternate default tags, define an alternate AWS provider with new default tags
and pass the new provider to the module.

```terraform
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

module "default-tags-dynamodb-alternate" {
  source = "./tfmodules/default-tags-dynamodb"
  providers = {
    aws = aws.alt-tags
  }
  .......
}
```
The final tags for `module.default-tags-dynamodb-alternate.aws_dynamodb_table.default-tags-module` are
```
"app-id" = "Terraform Default Tags"
"owner"  = "Alt Owner"
```

### Modules with both Default and Alternate Tags
If an AWS module requires both the default and alternate default tags, define the default and alternate AWS providers
and pass both providers to module. Then the module assigns the correct AWS provider to the AWS resource.

This is valuable since certain AWS resources like aws_s3_bucket_object have a **maximum limit of 10 tags**.

```terraform
locals {
  terraform-git-repo = "terraform-blog-default-tags"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner               = "Rocket Insights"
      project             = "Project A"
      terraform-base-path = replace(path.cwd, "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}

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
module "default-and-alternate-tags-dynamodb" {
  source = "./tfmodules/default-and-alternate-tags-dynamodb"
  providers = {
    aws          = aws
    aws.alt-tags = aws.alt-tags
  }
}
```

```terraform
// In ./tfmodules/default-and-alternate-tags-dynamodb
provider "aws" {
  alias = "aws"
}
provider "aws" {
  alias = "alt-tags"
}

resource "aws_dynamodb_table" "default-and-alternate-tags-module-basic" {
  name         = "default-and-alternate-tags-module-basic"
  .......
}

resource "aws_dynamodb_table" "default-and-alternate-tags-module-alternate" {
  provider     = aws.alt-tags
  name         = "default-and-alternate-tags-module-alternate"
  .......
}
```
The final tags for the two DynamoDB resources in the default-and-alternate-tags-dynamodb TF modules uses 
the assigned AWS provider tags

The final tags for `module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-basic` are
```terraform
// module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-basic
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

The final tags for `module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-alternate` are
```terraform
// module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-alternate
"app-id" = "Terraform Default Tags"
"owner"  = "Alt Owner"
```

### Modules and Adding and Overriding Default Tags
If an AWS module requires more tags in addition to the default tags, simply define the module tags 
variable and add the tag to the module.

```terraform
locals {
  terraform-git-repo = "terraform-blog-default-tags"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner    = "Rocket Insights"
      project  = "Project A"
      terraform-base-path = replace(path.cwd,
      "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}

module "default-tags-dynamodb-add" {
  source = "./tfmodules/default-tags-dynamodb-add"

  tags = {
    app-purpose = "Adding Module Tags"
  }
}
```
```terraform
// In ./tfmodules/default-tags-dynamodb-add
variable "tags" {
  type        = map(string)
  description = "Additional tags for DynamoDB table"
}
resource "aws_dynamodb_table" "default-tags-module-add" {
  name         = "default-tags-module-add"
  .......
  tags = merge(
    // path.module is a built-in Terraform variable that
    // describes the path of Terraform module
    // For this repo, the terraform-module-path is 
    // tfmodules/default-tags-dynamodb-add
    // Along with the terraform-base-path tag, this tag helps AWS UI users
    // discover what module repo to modify      
  Tagging Terraform module path helps maintenance      
    { terraform-module-path = path.module },
    var.tags
  )
}
```
The final tags for `module.default-tags-dynamodb-add.aws_dynamodb_table.default-tags-module-add` are
```
"app-purpose"           = "Adding Module Tags"
"owner"                 = "Rocket Insights"
"project"               = "Project A"
"terraform-base-path"   = "terraform-blog-default-tags/default-tags"
"terraform-module-path" = "tfmodules/default-tags-dynamodb-add
```

### Conclusion
Terraform default tags for AWS are an easy way to **add metadata to all AWS resources**.
Defining the default tags in one code location follows the best practice of **DRY (Don't Repeat Yourself)**.
If you have complex tagging requirements, **Terraform is customizable** to meet your needs.
