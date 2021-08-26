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
    // Tagging Terraform module path helps maintenance
    { terraform-module-path = path.module },
    var.tags
  )
}
