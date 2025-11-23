# ---------------------------------------------------------
# AWS DATABASE MODULE
# DynamoDB NoSQL Table con streaming habilitado
# ---------------------------------------------------------

resource "aws_dynamodb_table" "main_table" {
  name         = "${var.project_name}-TablaUsuarios"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Habilitamos streaming para sincronización con Azure
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = "${var.project_name}-DynamoDB"
  }
}
