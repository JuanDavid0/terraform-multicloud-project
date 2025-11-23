output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.app_tg.arn
}
