
# AWS NETWORKING MODULE
# Gestiona VPC, Subnets, Internet Gateway, NAT Gateway y Route Tables


# 1. Obtener las Zonas de Disponibilidad disponibles en la región
data "aws_availability_zones" "available" {
  state = "available"
}


# 2. VPC (Red Virtual Principal)

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-VPC"
  }
}


# 3. INTERNET GATEWAY (Puerta hacia Internet)

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}


# 4. SUBREDES PÚBLICAS (Zona 1 y Zona 2)

resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-Public-Subnet-${count.index + 1}"
  }
}


# 5. NAT GATEWAY (Salida para recursos privados)


# IP Elástica para el NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-NAT-EIP"
  }
}

# NAT Gateway en la primera subred pública
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.project_name}-NAT-GW"
  }

  depends_on = [aws_internet_gateway.igw]
}


# 6. SUBREDES PRIVADAS (Zona 1 y Zona 2)

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-Private-Subnet-${count.index + 1}"
  }
}


# 7. TABLAS DE ENRUTAMIENTO


# Tabla para recursos públicos
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-Public-RT"
  }
}

# Tabla para recursos privados
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name}-Private-RT"
  }
}


# 8. ASOCIACIONES DE TABLAS DE ENRUTAMIENTO


# Asociar subredes públicas a la tabla pública
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Asociar subredes privadas a la tabla privada
resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
