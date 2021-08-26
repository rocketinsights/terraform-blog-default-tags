module "default-tags-dynamodb" {
  source           = "./tfmodules/default-tags-dynamodb"
  tablename-suffix = "basic"
}
