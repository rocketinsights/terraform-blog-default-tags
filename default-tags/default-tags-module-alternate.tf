module "default-tags-dynamodb-alternate" {
  source = "./tfmodules/default-tags-dynamodb"
  providers = {
    aws = aws.alt-tags
  }

  tablename-suffix = "alternate"
}
