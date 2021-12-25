resource "aws_dynamodb_table" "exact-identical-bug" {
  name         = "exact-identical-bug"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "KeyId"

  attribute {
    name = "KeyId"
    type = "S"
  }

  # The resource tags are exactly identical to the AWS provider default_tags.
  # This causes the exception
  #    Error: "tags" are identical to those in the "default_tags" configuration block of the provider:
  #    please de-duplicate and try again
  # To fix, just delete the resource tags.
  tags = {
    owner   = "Rocket Insights"
    project = "Project A"
  }
}
