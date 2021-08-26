resource "aws_dynamodb_table" "default-tags-basic" {
  name         = "default-tags-basic"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }
}
