# ---------------------------------------------------------
# AWS LAMBDA MODULE
# Funciones Lambda para sincronización con Azure
# ---------------------------------------------------------

# ---------------------------------------------------------
# IAM ROLE para Lambdas
# ---------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-LambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ---------------------------------------------------------
# EMPAQUETAR CÓDIGO PYTHON
# ---------------------------------------------------------
data "archive_file" "zip_dynamo" {
  type        = "zip"
  source_file = var.dynamo_sync_code_path
  output_path = "${path.module}/dynamo_sync.zip"
}

data "archive_file" "zip_s3" {
  type        = "zip"
  source_file = var.s3_sync_code_path
  output_path = "${path.module}/s3_sync.zip"
}

# ---------------------------------------------------------
# LAMBDA PARA DYNAMODB -> AZURE
# ---------------------------------------------------------
resource "aws_lambda_function" "dynamo_sync" {
  filename      = data.archive_file.zip_dynamo.output_path
  function_name = "${var.project_name}-SyncDynamo"
  role          = aws_iam_role.lambda_role.arn
  handler       = "dynamo_sync.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  source_code_hash = data.archive_file.zip_dynamo.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.ecs_security_group_id]
  }

  environment {
    variables = {
      COSMOS_ENDPOINT = var.cosmos_endpoint
      COSMOS_KEY      = var.cosmos_primary_key
    }
  }
}

# TRIGGER: DynamoDB Stream
resource "aws_lambda_event_source_mapping" "dynamo_trigger" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.dynamo_sync.arn
  starting_position = "LATEST"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_dynamo,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# ---------------------------------------------------------
# SAS TOKEN para Azure Blob
# ---------------------------------------------------------
data "azurerm_storage_account_blob_container_sas" "blob_sas" {
  connection_string = var.azure_storage_connection_string
  container_name    = var.azure_container_name
  https_only        = true

  start  = "2025-01-01"
  expiry = "2026-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = false
    list   = true
  }
}

# ---------------------------------------------------------
# LAMBDA PARA S3 -> AZURE
# ---------------------------------------------------------
resource "aws_lambda_function" "s3_sync" {
  filename      = data.archive_file.zip_s3.output_path
  function_name = "${var.project_name}-SyncS3"
  role          = aws_iam_role.lambda_role.arn
  handler       = "s3_sync.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  source_code_hash = data.archive_file.zip_s3.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.ecs_security_group_id]
  }

  environment {
    variables = {
      AZURE_SAS_URL = "https://${var.azure_storage_account_name}.blob.core.windows.net/${var.azure_container_name}?${data.azurerm_storage_account_blob_container_sas.blob_sas.sas}"
    }
  }
}

# TRIGGER: S3 Notification Permission
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_sync.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_sync.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
