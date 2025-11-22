# ---------------------------------------------------------
# DYNAMODB TABLE
# Base de datos NoSQL Serveless
# ---------------------------------------------------------
resource "aws_dynamodb_table" "main_table" {
  name         = "${var.proyecto_nombre}-TablaUsuarios"
  billing_mode = "PAY_PER_REQUEST" # Ideal para retos/tier free, solo pagas si la usas
  
  # Llave primaria (Partition Key) - Ejemplo: 'id' del usuario o transacción
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S" # S = String, N = Number
  }

  # ---------------------------------------------------------
  # CONFIGURACIÓN CLAVE PARA LA REPLICACIÓN A AZURE
  # ---------------------------------------------------------
  stream_enabled   = true
  # NEW_AND_OLD_IMAGES permite ver qué cambió exactamente para enviarlo a Azure
  stream_view_type = "NEW_AND_OLD_IMAGES" 

  tags = {
    Name = "${var.proyecto_nombre}-DynamoDB"
  }
}