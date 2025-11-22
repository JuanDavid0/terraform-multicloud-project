# 1. Obtener las Zonas de Disponibilidad (AZ) disponibles en la región
# Esto hace que el código sirva para cualquier región sin cambios manuales
data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------
# 2. INTERNET GATEWAY (IGW)
# Es la "puerta principal" de la VPC hacia internet.
# Sin esto, nadie puede entrar ni salir.
# ---------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.proyecto_nombre}-IGW"
  }
}

# ---------------------------------------------------------
# 3. SUBREDES PÚBLICAS (Zona 1 y Zona 2)
# Aquí pondremos el Load Balancer y el NAT Gateway.
# ---------------------------------------------------------
resource "aws_subnet" "public_subnets" {
  count                   = 2 # Crea 2 subredes (una por cada CIDR definido en variables)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Asigna IP pública automáticamente

  tags = {
    Name = "${var.proyecto_nombre}-Public-Subnet-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# 4. NAT GATEWAY (Costo $$$)
# Permite que las Lambdas/Contenedores PRIVADOS salgan a internet (hacia Azure)
# pero impide que internet entre directamente a ellos.
# ---------------------------------------------------------

# Primero necesitamos una IP Elástica (IP Fija)
resource "aws_eip" "nat_eip" {
  domain = "vpc" 
}

# Creamos el NAT Gateway en la PRIMERA subred pública
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.proyecto_nombre}-NAT-GW"
  }

  # Para asegurar el orden, esperamos a que exista el IGW
  depends_on = [aws_internet_gateway.igw]
}

# ---------------------------------------------------------
# 5. SUBREDES PRIVADAS (Zona 1 y Zona 2)
# Aquí vivirán tus Microservicios, DynamoDB y Lambdas.
# Son invisibles desde internet directo.
# ---------------------------------------------------------
resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.proyecto_nombre}-Private-Subnet-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# 6. TABLAS DE ENRUTAMIENTO (El mapa de navegación)
# ---------------------------------------------------------

# Tabla para lo PÚBLICO: Todo el tráfico (0.0.0.0/0) va al Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.proyecto_nombre}-Public-RT"
  }
}

# Tabla para lo PRIVADO: Todo el tráfico de salida va al NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.proyecto_nombre}-Private-RT"
  }
}

# ---------------------------------------------------------
# 7. ASOCIACIONES DE TABLAS
# Conectamos las subredes a sus respectivas tablas
# ---------------------------------------------------------

# Asociar las 2 subredes públicas a la tabla pública
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Asociar las 2 subredes privadas a la tabla privada
resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}