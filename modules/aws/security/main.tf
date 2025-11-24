# AWS SECURITY MODULE
# Security Groups para ALB y ECS/Fargate

# 1. SECURITY GROUP PARA EL LOAD BALANCER (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-ALB-SG"
  description = "Permitir trafico HTTP desde internet"
  vpc_id      = var.vpc_id

  # Regla de ENTRADA: Aceptamos HTTP (Puerto 80) de cualquier lugar
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de SALIDA: El ALB puede hablar hacia afuera sin restricciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ALB-SG"
  }
}


# 2. SECURITY GROUP PARA LOS MICROSERVICIOS (ECS/Fargate)

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ECS-SG"
  description = "Permitir trafico solo desde el ALB"
  vpc_id      = var.vpc_id

  # Regla de ENTRADA: SOLO permitimos tráfico que venga del Security Group del ALB
  ingress {
    description     = "Traffic from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Regla de SALIDA: Los contenedores necesitan salir a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ECS-SG"
  }
}
