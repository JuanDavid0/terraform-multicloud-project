# ---------------------------------------------------------
# IAM ROLE FOR ECS EXECUTION
# Permite a Fargate descargar imágenes de ECR y crear logs.
# ---------------------------------------------------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.proyecto_nombre}-ECSExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ---------------------------------------------------------
# IAM ROLE FOR ECS TASK (Permisos de la APP Python)
# Permite que el código Python hable con S3 y DynamoDB
# ---------------------------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.proyecto_nombre}-ECSTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Permiso FULL para DynamoDB (Para que la app escriba)
resource "aws_iam_role_policy_attachment" "task_dynamo" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Permiso FULL para S3 (Para que la app suba archivos)
resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Adjuntar la política maestra de AWS para ejecución de tareas
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------
# 1. ELASTIC CONTAINER REGISTRY (ECR)
# Creamos 3 repositorios, uno para cada microservicio.
# ---------------------------------------------------------
resource "aws_ecr_repository" "microservicios" {
  count                = 3
  name                 = "${lower(var.proyecto_nombre)}-service-${count.index + 1}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Permite borrar el repo aunque tenga imágenes (para el reto)

  tags = {
    Name = "Repo-Microservicio-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# 2. ECS CLUSTER
# El "cerebro" que agrupa tus servicios.
# ---------------------------------------------------------
resource "aws_ecs_cluster" "main_cluster" {
  name = "${var.proyecto_nombre}-Cluster"
}

# ---------------------------------------------------------
# 3. TASK DEFINITION (El Plano del Contenedor)
# Define cuánta CPU/RAM usa y qué imagen corre.
# ---------------------------------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.proyecto_nombre}-Task"
  network_mode             = "awsvpc" # Obligatorio para Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    # 0.25 vCPU (Mínimo para ahorrar costos)
  memory                   = "512"    # 512 MB RAM
  
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # Definición del contenedor (en formato JSON)
  container_definitions = jsonencode([
    {
      name      = "microservicio-demo"
      image     = "324315783637.dkr.ecr.us-east-1.amazonaws.com/retofinalcloud-service-1:latest" # IMAGEN TEMPORAL para que Terraform no falle
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ],
      environment = [
        { name = "DYNAMO_TABLE", value = aws_dynamodb_table.main_table.name },
        { name = "S3_BUCKET",    value = aws_s3_bucket.main_bucket.id },
        { name = "AWS_REGION",   value = var.aws_region }
      ]
    }
  ])
}

# ---------------------------------------------------------
# 4. ECS SERVICE (La Ejecución Real)
# Mantiene los contenedores vivos y los conecta al ALB.
# ---------------------------------------------------------
resource "aws_ecs_service" "main_service" {
  name            = "${var.proyecto_nombre}-Service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # Alta disponibilidad: 2 copias corriendo

  # Configuración de Red (Dónde viven los contenedores)
  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id # Subredes PRIVADAS [cite: 49]
    security_groups  = [aws_security_group.ecs_sg.id]   # Solo tráfico desde el ALB
    assign_public_ip = false                            # Privacidad total
  }

  # Conexión con el Balanceador de Carga
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "microservicio-demo"
    container_port   = 80
  }

  # Esperamos a que el Listener del ALB exista para evitar errores de carrera
  depends_on = [aws_lb_listener.front_end]
}