resource "aws_dynamodb_table" "default-and-alternate-tags-module-basic" {
  name         = "default-and-alternate-tags-module-basic"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "default-and-alternate-tags-module-alternate" {
  provider     = aws.alt-tags
  name         = "default-and-alternate-tags-module-alternate"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}
