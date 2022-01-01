## Best Practices for Terraform AWS Tags: Part 2

Rocket Insights [blog article here](https://blog.rocketinsights.com/best-practices-for-terraform-aws-tags-part-2/)

Thank you for making the original Terraform AWS Tags [blog post](README.md) so popular. As of December 2021, it is a first page Google search result for
[`aws terraform tags`](https://www.google.com/search?q=aws+terraform+tags).

I gave a presentation about Terraform AWS tags at the Boston DevOps Meetup. The attendees and I had a lively discussion afterwards. 
The feedback to that talk inspired me to write this follow-up article.

The main topics of conversation centered around using Terraform AWS default_tags in production.

* Workarounds for default_tags bugs
* Access individual default tags
* ASG and LT tags tips and trick
* EC2 volume tags tips and tricks
* AWS Resource Groups and Tag Editors

### Workarounds for default_tags bugs
Especially when refactoring existing Terraform code to use default_tags, you will run into two common bugs:
* Exactly identical tags bug
* Partially identical tags bug

#### Exactly identical tags bug
Terraform example of bug and workaround here on Rocket Insights GitHub repo.

```terraform
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

#### Partially identical tags bug
Terraform example of bug and workaround here on Rocket Insights GitHub repo.

When the AWS provider default_tags and the resource tags have some identical entries, terraform plan will always show an update on the tags even though there are no changes.

The above Terraform code will always show the following terraform plan

To work around this bug, just delete the duplicate resource tags

### Access individual default tags
Terraform example of the default_tags data source here on Rocket Insights GitHub repo.
Using the Terraform aws_default_tags data source, you can get programmatic access to an individual key and value of default tags.
This example shows how to use the user defined environment default tag to determine whether to create an DynamoDB table.

### ASG and LT tags tips and tricks
Terraform example of ASG and LT tagging here on Rocket Insights GitHub repo.
Auto scaling groups (ASG) and launch templates (LT) are tricky to get tagging correct. Unless you configure it correctly, the EC2 instance and attached storage volumes launched by the ASG and LT will not have the default tags attached.
Launch templates require the tag_specifications configuration and ASGs require the propagate_at_launch tag configuration.

### EC2 EBS volume tags tips and tricks
Terraform example of EC2 EBS tagging here on Rocket Insights GitHub repo.
When you create Elastic Compute (EC2) instances via Terraform, the Elastic Block Store (EBS) volumes attached to the EC2 are not automatically tagged. Untagged EBS volumes are cumbersome to administer.
You assign the EC2 default tags to the attached EBS storage volume with the aws_instance volume_tags .

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