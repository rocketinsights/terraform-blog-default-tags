resource "aws_dynamodb_table" "default-tags-module-add" {
  name         = "default-tags-module-add"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }

  // Merge multiple tags maps into one tags map
  // https://www.terraform.io/docs/language/functions/merge.html
  tags = merge(
      // path.module is a built-in Terraform variable that
      // describes the path of Terraform module
      // For this repo, the terraform-module-path is
      // tfmodules/default-tags-dynamodb-add
      // Along with the terraform-base-path tag, this tag helps AWS UI users
      // discover what module repo to modify
    { terraform-module-path = path.module },
    var.tags
  )
}
