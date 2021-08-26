resource "aws_dynamodb_table" "default-tags-add" {
  name         = "default-tags-add"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }

  tags = {
    project     = "Project Override"
    sub-project = "Subproject Add"
  }
}
