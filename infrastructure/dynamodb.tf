# This mostly exists to make querying easier because Cognito's APIs are dogshit
resource "aws_dynamodb_table" "users" {
  name                        = "${local.prefix}users"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
