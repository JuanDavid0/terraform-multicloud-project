# ---------------------------------------------------------
# 1. SECURITY GROUP PARA EL LOAD BALANCER (ALB)
# Este es el "portero" de la puerta principal.
# ---------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.proyecto_nombre}-ALB-SG"
  description = "Permitir trafico HTTP desde internet"
  vpc_id      = aws_vpc.main_vpc.id

  # Regla de ENTRADA (Ingress): Aceptamos HTTP (Puerto 80) de cualquier lugar
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 significa "Todo el mundo"
  }

  # Regla de SALIDA (Egress): El ALB puede hablar hacia afuera sin restricciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.proyecto_nombre}-ALB-SG"
  }
}

# ---------------------------------------------------------
# 2. SECURITY GROUP PARA LOS MICROSERVICIOS (ECS/Fargate)
# Este es el "portero" interno. Muy estricto.
# ---------------------------------------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "${var.proyecto_nombre}-ECS-SG"
  description = "Permitir trafico solo desde el ALB"
  vpc_id      = aws_vpc.main_vpc.id

  # Regla de ENTRADA: SOLO permitimos tráfico que venga del Security Group del ALB
  ingress {
    description     = "Traffic from ALB only"
    from_port       = 80            # O el puerto que usen tus contenedores (ej: 3000, 8080)
    to_port         = 80            # Si tus containers usan otro, cámbialo aquí
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ¡Aquí ocurre la magia del encadenamiento!
  }

  # Regla de SALIDA: Los contenedores necesitan salir a internet (vía NAT Gateway)
  # para descargar actualizaciones o llamar a la API de Azure (Sync)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.proyecto_nombre}-ECS-SG"
  }
}