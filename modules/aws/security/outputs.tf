output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb_sg.id
}

output "ecs_security_group_id" {
  description = "ID del Security Group para ECS/Fargate"
  value       = aws_security_group.ecs_sg.id
}
