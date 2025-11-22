# ---------------------------------------------------------
# IAM ROLE (Permisos para las Lambdas)
# Las Lambdas necesitan permiso para:
# 1. Crear logs en CloudWatch
# 2. Leer de DynamoDB y S3
# 3. Crear interfaces de red (porque están en VPC)
# ---------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.proyecto_nombre}-LambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Adjuntar política básica de ejecución (Logs + VPC)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Adjuntar política de lectura de DynamoDB
resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

# Adjuntar política de lectura de S3
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ---------------------------------------------------------
# EMPAQUETAR CÓDIGO PYTHON
# Terraform comprime los archivos .py en .zip automáticamente
# ---------------------------------------------------------
data "archive_file" "zip_dynamo" {
  type        = "zip"
  source_file = "lambda_code/dynamo_sync.py"
  output_path = "lambda_code/dynamo_sync.zip"
}

data "archive_file" "zip_s3" {
  type        = "zip"
  source_file = "lambda_code/s3_sync.py"
  output_path = "lambda_code/s3_sync.zip"
}

# ---------------------------------------------------------
# 1. LAMBDA PARA DYNAMODB -> AZURE
# ---------------------------------------------------------
resource "aws_lambda_function" "dynamo_sync" {
  filename      = data.archive_file.zip_dynamo.output_path
  function_name = "${var.proyecto_nombre}-SyncDynamo"
  role          = aws_iam_role.lambda_role.arn
  handler       = "dynamo_sync.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  source_code_hash = data.archive_file.zip_dynamo.output_base64sha256

  # Red: La ponemos en la VPC privada para salir por el NAT Gateway
  vpc_config {
    subnet_ids         = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.ecs_sg.id] # Reusamos el SG interno
  }

  environment {
    variables = {
      COSMOS_ENDPOINT = azurerm_cosmosdb_account.cosmos_acc.endpoint
      COSMOS_KEY      = azurerm_cosmosdb_account.cosmos_acc.primary_key
    }
  }
}

# TRIGGER: Conectar DynamoDB Stream a esta Lambda
resource "aws_lambda_event_source_mapping" "dynamo_trigger" {
  event_source_arn  = aws_dynamodb_table.main_table.stream_arn
  function_name     = aws_lambda_function.dynamo_sync.arn
  starting_position = "LATEST"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_dynamo,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# ---------------------------------------------------------
# 2. LAMBDA PARA S3 -> AZURE
# ---------------------------------------------------------
# Necesitamos generar una URL SAS (Token de acceso temporal) para Azure Blob
# Terraform puede generar esto al momento del despliegue.
data "azurerm_storage_account_blob_container_sas" "blob_sas" {
  connection_string = azurerm_storage_account.azure_sa.primary_connection_string
  container_name    = azurerm_storage_container.azure_container.name
  https_only        = true

  start  = "2025-01-01"
  expiry = "2026-01-01" # Token valido por un año para el reto

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = false
    list   = true
  }
}

resource "aws_lambda_function" "s3_sync" {
  filename      = data.archive_file.zip_s3.output_path
  function_name = "${var.proyecto_nombre}-SyncS3"
  role          = aws_iam_role.lambda_role.arn
  handler       = "s3_sync.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  source_code_hash = data.archive_file.zip_s3.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.ecs_sg.id]
  }

  environment {
    variables = {
      # Armamos la URL completa con el token SAS
      AZURE_SAS_URL = "https://${azurerm_storage_account.azure_sa.name}.blob.core.windows.net/${azurerm_storage_container.azure_container.name}?${data.azurerm_storage_account_blob_container_sas.blob_sas.sas}"
    }
  }
}

# TRIGGER: S3 Notification
# Damos permiso a S3 para invocar la Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_sync.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main_bucket.arn
}

# Configuramos la notificación en el bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.main_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_sync.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}