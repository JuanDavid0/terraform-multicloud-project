output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR"
  value       = aws_ecr_repository.microservicios[*].repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main_cluster.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.main_service.name
}

output "ecs_task_role_arn" {
  description = "ARN del IAM role de la tarea ECS"
  value       = aws_iam_role.ecs_task_role.arn
}
