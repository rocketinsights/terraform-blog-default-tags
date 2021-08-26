resource "aws_dynamodb_table" "default-tags-module" {
  name         = "default-tags-module-${var.tablename-suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}
