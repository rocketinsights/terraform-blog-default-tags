module "default-tags-dynamodb-add" {
  source = "./tfmodules/default-tags-dynamodb-add"

  tags = {
    app-purpose = "Adding Module Tags"
  }
}
