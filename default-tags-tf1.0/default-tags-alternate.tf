resource "aws_dynamodb_table" "default-tags-alternate" {
  provider     = aws.alt-tags
  name         = "default-tags-alternate"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}
