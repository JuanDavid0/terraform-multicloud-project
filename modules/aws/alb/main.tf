
# AWS ALB (Application Load Balancer) MODULE
# Gestiona el Load Balancer, Target Group y Listener



# APPLICATION LOAD BALANCER

resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-ALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-ALB"
  }
}


# TARGET GROUP

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_name}-TG"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }

  tags = {
    Name = "${var.project_name}-TG"
  }
}


# LISTENER

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
