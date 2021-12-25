resource "aws_dynamodb_table" "exact-identical-workaround" {
  name         = "exact-identical-workaround"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }

  # To fix the exactly identical tags bug, just delete the duplicate resource tags
}
