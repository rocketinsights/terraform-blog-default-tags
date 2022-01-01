## Best Practices for Terraform AWS Tags: Part 2

Rocket Insights [blog article here](https://blog.rocketinsights.com/best-practices-for-terraform-aws-tags-part-2/)

Thank you for making the original Terraform AWS Tags [blog post](README.md) so popular. As of December 2021, it is a first page Google search result for
[`aws terraform tags`](https://www.google.com/search?q=aws+terraform+tags).

I gave a presentation about Terraform AWS tags at the Boston DevOps Meetup. The attendees and I had a lively discussion afterwards. 
The feedback to that talk inspired me to write this follow-up article.

The main topics of conversation centered around using Terraform AWS default_tags in production.

* Workarounds for default_tags bugs
* Access individual default tags
* ASG and LT tags tips and tricks
* EC2 volume tags tips and tricks
* AWS Resource Groups and Tag Editors

### Workarounds for default_tags bugs
Especially when refactoring existing Terraform code to use default_tags, you will run into two common bugs:
* [Exactly identical tags bug](https://github.com/hashicorp/terraform-provider-aws/issues/19204)
* [Partially identical tags bug](https://github.com/hashicorp/terraform-provider-aws/issues/19204#issuecomment-840753622)

#### Exactly identical tags bug
Terraform example of bug and workaround here on [Rocket Insights GitHub repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/bugs-workarounds/exact-identical).

```
Error: "tags" are identical to those in the "default_tags" configuration block of the provider: 
please de-duplicate and try again
```
When the AWS provider default_tags and the resource tags are exactly the same, you will get the above error.

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

resource "aws_dynamodb_table" "exact-identical-bug" {
  name         = "exact-identical-bug"

  # The resource tags are exactly identical to the 
  # AWS provider default_tags.
  # This causes the exception
  #
  # Error: "tags" are identical to those in the 
  #   "default_tags" configuration block of the provider:
  #   please de-duplicate and try again
  #
  # To fix, just delete the resource tags.
  tags = {
    owner   = "Rocket Insights"
    project = "Project A"
  }
} 
```
To work around the "exactly identical tags bug", just delete the duplicated resource tags.

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

resource "aws_dynamodb_table" "exact-identical-workaround" {
  name         = "exact-identical-workaround"

  # To fix the exactly identical tags bug, 
  # just delete the duplicate resource tags
}
```
#### Partially identical tags bug
Terraform example of bug and workaround here on [Rocket Insights GitHub repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/bugs-workarounds/partial-identical).

When the AWS provider default_tags and the resource tags have some identical entries, 
`terraform plan` will always show an update on the tags even though there are no changes.

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

resource "aws_dynamodb_table" "partial-identical-bug" {
  name         = "partial-identical-bug"

  # The resource tags have some entries that are identical
  # to the AWS provider default_tags. 
  # This causes `terraform plan` to always show 
  # an update on the tags even though there are no changes.
  # To fix, just delete the duplicated resource tags.
  tags = {
    owner   = "Rocket Insights"
    project = "Project A"
    cost-center = "Rocket Insights Billing"
  }
}  
```

The above Terraform code will always show the following `terraform plan`

```
Terraform will perform the following actions:

  # aws_dynamodb_table.partial-identical-bug will be updated in-place
  ~ resource "aws_dynamodb_table" "partial-identical-bug" {
        id             = "partial-identical-bug"
        name           = "partial-identical-bug"
      ~ tags           = {
          + "owner"       = "Rocket Insights"
          + "project"     = "Project A"
            # (1 unchanged element hidden)
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.


```

To work around this bug, just delete the duplicate resource tags

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

resource "aws_dynamodb_table" "partial-identical-workaround" {
  name         = "partial-identical-workaround"

  # To fix, just delete the duplicated resource tags.
  tags = {
    cost-center = "Rocket Insights Billing"
  }
}
```

### Access individual default tags
Terraform example of the default_tags data source here on [Rocket Insights GitHub repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/aws-default-tags-ds-examples/asg).

Using the Terraform **[aws_default_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags)** data source,
you can get programmatic access to an individual key and value of default tags.

This example shows how to use the user defined environment default tag to determine whether to create an DynamoDB table.

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner       = "Rocket Insights"
      project     = "Project A"
      environment = "dev"  # Change dev to prod to add the prod DynamoDB
    }
  }
}

# Access individual default_tags via the data source
data "aws_default_tags" "provider" {}

resource "aws_dynamodb_table" "prod-only" {
  # Only create this DynamoDB table if the 
  # `environment` default tag value is `prod`
  count = data.aws_default_tags.provider.tags.environment == "prod" ? 1 : 0
  name  = "default-tags-prod-db"
}
```
### ASG and LT tags tips and tricks
Terraform example of ASG and LT tagging here on [Rocket Insights GitHub repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/aws-default-tags-ds-examples/asg).

Auto Scaling Groups ([ASG](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)) 
and Launch Templates ([LT](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchTemplates.html)) are tricky to tag correctly.
Without the right configurations, the EC2 instance and attached storage volumes launched by the ASG and LT will not have the default tags attached.

Launch templates require the **[tag_specifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#tag-specifications)** configuration
and ASGs require the **[propagate_at_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#propagate_at_launch)** tag configuration.

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

# Access individual default_tags via the data source
data "aws_default_tags" "provider" {}

resource "aws_autoscaling_group" "default-tags-asg" {
  name = "default-tags-asg"

  # Loops through the AWS provider default_tags to generate
  # multiple aws_autoscaling_group specific propagate_at_launch tag.
  # Any EC2 instances launched by this ASG will have these tags
  # automatically attached.
  dynamic "tag" {
    for_each = data.aws_default_tags.provider.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  launch_template {
    id      = aws_launch_template.default-tags-lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "default-tags-lt" {
  name          = "default-tags-lt"

  # The EBS volume of the EC2 instances created 
  # by this launch template
  # will have these tags automatically attached
  tag_specifications {
    resource_type = "volume"
    # merge is a Terraform built-in function to combine maps
    tags = merge(
      {
        Name = "default-tags-lt-volume"
      },
      data.aws_default_tags.provider.tags
    )
  }
}
```

### EC2 EBS volume tags tips and tricks
Terraform example of EC2 EBS tagging here on [Rocket Insights GitHub repo](https://github.com/rocketinsights/terraform-blog-default-tags/tree/main/aws-default-tags-ds-examples/volume-tags).

When you create Elastic Compute ([EC2](https://aws.amazon.com/ec2/)) instances via Terraform, 
the Elastic Block Store ([EBS](https://aws.amazon.com/ebs/)) volumes attached to the EC2 are not automatically tagged.
Untagged EBS volumes are cumbersome to administer.

You assign the EC2 default tags to the attached EBS storage volume with the aws_instance [volume_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#volume_tags) .

```terraform
provider "aws" {
  default_tags {
    tags = {
      owner   = "Rocket Insights"
      project = "Project A"
    }
  }
}

# Access individual default_tags via the data source
data "aws_default_tags" "provider" {}

resource "aws_instance" "default-tags-ec2" {
  ami = data.aws_ami.default-tags-ami.id
  instance_type = "t2.micro"

  # Assigns the default tags to volumes 
  # attached to this EC2 instance
  volume_tags = data.aws_default_tags.provider.tags
}
```
### AWS Resource Groups and Tag Editors
Have you ever wanted to do the following: 
"Find all AWS resources in all regions that have the tag `owner='Rocket Insights' " ?

To perform the above query, AWS introduced [Resource Groups and Tag Editors](https://docs.aws.amazon.com/ARG/latest/userguide/resource-groups.html)
. Resource groups are a way to manage the tags of multiple AWS resources in one place.

The topic of Resource Groups can be its own article. In a brief summary, here are some of the things you can do with Resource Groups and Tag Editors.
* Find AWS resources across regions with a specific tag
* Find AWS resources without tags
* Add or edit tags of multiple AWS resources at one time
* Upgrade all AWS resources with a specific tag
* 
The AWS UI for Resource Groups is clunky but if you experiment with it, 
it can be a powerful tool in your AWS administration toolbox.

### Conclusion
Introducing a new technology into production is never easy. There are always bugs, workarounds, and traps.
Terraform AWS default_tags are no exception to the above truth. Hopefully this follow-up article can provide solutions 
for easier implementation of Terraform AWS tags in production.