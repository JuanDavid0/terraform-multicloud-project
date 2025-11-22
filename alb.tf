# ---------------------------------------------------------
# APPLICATION LOAD BALANCER (ALB)
# Recibe el tráfico de internet.
# ---------------------------------------------------------
resource "aws_lb" "app_alb" {
  name               = "${var.proyecto_nombre}-ALB"
  internal           = false # false = Mira hacia internet
  load_balancer_type = "application"
  
  # Lo conectamos a los Security Groups "Porteros" que creamos antes
  security_groups    = [aws_security_group.alb_sg.id]
  
  # Lo ponemos en las Subredes PÚBLICAS para que internet lo alcance
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name = "${var.proyecto_nombre}-ALB"
  }
}

# ---------------------------------------------------------
# TARGET GROUP
# Es un "grupo destino". El ALB enviará el tráfico aquí.
# Luego, los contenedores se "suscribirán" a este grupo.
# ---------------------------------------------------------
resource "aws_lb_target_group" "app_tg" {
  name        = "${var.proyecto_nombre}-TG"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip" # IMPORTANTE: Para Fargate se usa 'ip', no 'instance'
  vpc_id      = aws_vpc.main_vpc.id

  # Health Check: El ALB revisa constantemente si los contenedores están vivos
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# ---------------------------------------------------------
# LISTENER (El Oído del ALB)
# Escucha en el puerto 80 y redirige al Target Group
# ---------------------------------------------------------
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}