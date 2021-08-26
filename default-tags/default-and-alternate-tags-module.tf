module "default-and-alternate-tags-dynamodb" {
  source = "./tfmodules/default-and-alternate-tags-dynamodb"
  providers = {
    aws          = aws
    aws.alt-tags = aws.alt-tags
  }
}
