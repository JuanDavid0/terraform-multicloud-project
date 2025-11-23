output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = aws_subnet.private_subnets[*].id
}

output "private_route_table_id" {
  description = "ID de la tabla de enrutamiento privada (para VPC endpoints)"
  value       = aws_route_table.private_rt.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = aws_nat_gateway.nat_gw.id
}
