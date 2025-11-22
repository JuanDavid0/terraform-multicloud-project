# ---------------------------------------------------------
# GENERADOR DE ID ALEATORIO
# Los nombres de los Buckets S3 deben ser ÚNICOS en todo el mundo.
# Esto añade unos caracteres al azar al final para que no te de error.
# ---------------------------------------------------------
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------
# BUCKET S3 PRINCIPAL
# Aquí se guardarán los archivos PDF de los microservicios.
# ---------------------------------------------------------
resource "aws_s3_bucket" "main_bucket" {
  # El nombre final será algo como: retofinalcloud-files-bucket-a1b2c3
  bucket = "${lower(var.proyecto_nombre)}-files-bucket-${random_string.bucket_suffix.result}"
  
  # force_destroy permite borrar el bucket aunque tenga archivos dentro 
  # (Útil para entornos de pruebas/retos para que 'terraform destroy' no falle)
  force_destroy = true 

  tags = {
    Name = "${var.proyecto_nombre}-S3-Bucket"
  }
}

# ---------------------------------------------------------
# BLOQUEO DE ACCESO PÚBLICO
# Por seguridad, nos aseguramos que NADIE en internet pueda ver esto.
# ---------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------
# VPC ENDPOINT (GATEWAY)
# Este es el "Túnel" que conecta tu Subred Privada con S3.
# Permite que los microservicios guarden archivos sin salir a Internet.
# Cumple el requisito de privacidad del diagrama.
# ---------------------------------------------------------
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Conectamos este túnel a la Tabla de Rutas PRIVADA
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = {
    Name = "${var.proyecto_nombre}-S3-Endpoint"
  }
}

# NOTA: La configuración de la notificación (Trigger) para la Lambda
# la agregaremos más adelante cuando creemos el archivo 'compute.tf'
# para evitar errores de "El recurso Lambda no existe aún".