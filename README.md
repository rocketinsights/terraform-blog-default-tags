## Best Practice for Terraform AWS Tags

[AWS tags](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) are key-value labels you can assign to AWS resources 
that give extra information about it. 

For example, you can tag an EC2 instance with _owner = Rocket Insights_. This tells an AWS admin the contact information 
in case the server has errors. The owner tag can be used by AWS Billing to see how much money that owner is spending
each month. Automation tools can filter for the owner tag to only update those servers.

Starting with [Terraform](https://www.terraform.io/) 0.12.31 and AWS provider v3.38.0, Hashicorp added the default tags feature.
You can now **configure AWS tags in one place** and **automatically apply them to all AWS resources**. You no longer have to manually 
add `tags` blocks to each individual AWS resource. 

As a best practice, tagging the Terraform base and module path results in easier codebase maintenance.

This Terraform AWS default tags tutorial will show ...
* Basic usage
* Adding and overriding tags to the default
* Providing alternate default tags

For the full Terraform code, please visit the Rocket Insights [Github repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main).

### Basic Usage

The default tags are defined in the AWS provider section. It will automatically be applied
to all AWS resources

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
      // Tagging Terraform path helps maintenance
      terraform-base-path = replace(path.cwd, "/^.*?(${local.terraform-git-repo}\\/)/", "$1")
    }
  }
}
resource "aws_dynamodb_table" "default-tags-basic" {
  name     = "default-tags-basic"
  .......
}

``` 
The final tags for aws_dynamodb_table.default-tags-basic are

```
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

### Add and Override default tags
If an AWS resource requires more tags in addition to the default tags, simply add the tag to the
built-in resource `tags` block.

If an AWS resource requires to override a default tag, define a tag with the same key in the `tag`
block

```terraform
resource "aws_dynamodb_table" "default-tags-add" {
  name     = "default-tags-add"
  .......
  
  tags = {
    project     = "Project Override"
    sub-project = "Subproject Add"
  }
}

```  
The final tags for aws_dynamodb_table.default-tags-add are

```
"owner"               = "Rocket Insights"
"project"             = "Project Override"
"sub-project"         = "Subproject Add"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

### Alternate Default Tags
If an AWS resource requires alternate default tags, an alternate AWS provider with new default tags can be defined

```terraform
provider "aws" {
  alias  = "alt-tags"
  region = "us-east-1"
  default_tags {
    tags = {
      modified   = "Terraform"
      owner      = "Owner B"
    }
  }
}

resource "aws_dynamodb_table" "default-tags-alternate" {
  provider = aws.alt-tags
  name     = "default-tags-alternate"
  ........
}
```
The final tags for aws_dynamodb_table.default-tags-alternate are
```
"modified"   = "Terraform"
"owner"      = "Owner B"
```

### Modules and Default Tags
The AWS default tags apply to existing Terraform AWS modules without any changes needed

```terraform
module "default-tags-dynamodb" {
  source = "./tfmodules/default-tags-dynamodb"
}
```
The final tags for module.default-tags-dynamodb.aws_dynamodb_table.default-tags-module are
```
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```

### Add and Override default tags
If an AWS module requires more tags in addition to the default tags, simply define the module tags 
variable and add the tag to the module

```terraform
module "default-tags-dynamodb-add" {
  source = "./tfmodules/default-tags-dynamodb-add"

  tags = {
    module-project = "Adding Module Tags"
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
    // Tagging Terraform module path helps maintenance      
    { terraform-module-path = path.module },
    var.tags
  )
}
```
The final tags for module.default-tags-dynamodb-add.aws_dynamodb_table.default-tags-module-add are
```
"module-project"        = "Adding Module Tags"
"owner"                 = "Rocket Insights"
"project"               = "Project A"
"terraform-base-path"   = "terraform-blog-default-tags/default-tags"
"terraform-module-path" = "tfmodules/default-tags-dynamodb-add
```

### Modules and Alternate Tags
If an AWS module requires alternate default tags, an alternate AWS provider with new default tags can be defined
and the new provider can be passed to module

```terraform
module "default-tags-dynamodb-alternate" {
  source = "./tfmodules/default-tags-dynamodb"
  providers = {
    aws = aws.alt-tags
  }
  .......
}
```
The final tags for module.default-tags-dynamodb-alternate.aws_dynamodb_table.default-tags-module are
```
"modified" = "Terraform"
"owner"    = "Owner B"
```
### Modules with both Default and Alternate Tags
If an AWS module requires both the default and alternate default tags, the default and alternate AWS providers can be defined
and both providers can be passed to module. Then the module can assign which AWS resource uses which AWS provider.

This is valuable since certain AWS resources like aws_s3_bucket_object have a maximum limit of 10 tags.

```terraform
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
The final tags for the two DynamoDB resources in the default-and-alternate-tags-dynamodb TF modules
will use the assigned AWS provider tags
```terraform
// module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-basic
"owner"               = "Rocket Insights"
"project"             = "Project A"
"terraform-base-path" = "terraform-blog-default-tags/default-tags"
```
```terraform
// module.default-and-alternate-tags-dynamodb.aws_dynamodb_table.default-and-alternate-tags-module-alternate
"modified" = "Terraform"
"owner"    = "Owner B"
```

### Conclusion
Terraform default tags for AWS is an easy way to **add metadata to all AWS resources**.
Defining the default tags in one code location follows the best practice of **DRY (Don't Repeat Yourself)**.
If you have complex tagging requirements, **Terraform is customizable** to meet your needs.
