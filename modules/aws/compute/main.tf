# ---------------------------------------------------------
# AWS COMPUTE MODULE
# ECR, ECS, IAM Roles para contenedores Fargate
# ---------------------------------------------------------

# ---------------------------------------------------------
# IAM ROLE FOR ECS EXECUTION
# ---------------------------------------------------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ECSExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ---------------------------------------------------------
# IAM ROLE FOR ECS TASK
# ---------------------------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ECSTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Permisos para DynamoDB
resource "aws_iam_role_policy_attachment" "task_dynamo" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Permisos para S3
resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Política de ejecución de ECS
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------
# ELASTIC CONTAINER REGISTRY (ECR)
# ---------------------------------------------------------
resource "aws_ecr_repository" "microservicios" {
  count                = var.ecr_repository_count
  name                 = "${lower(var.project_name)}-service-${count.index + 1}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = "Repo-Microservicio-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# ECS CLUSTER
# ---------------------------------------------------------
resource "aws_ecs_cluster" "main_cluster" {
  name = "${var.project_name}-Cluster"
}

# ---------------------------------------------------------
# TASK DEFINITION
# ---------------------------------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-Task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "microservicio-demo"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ],
      environment = [
        { name = "DYNAMO_TABLE", value = var.dynamodb_table_name },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "AWS_REGION", value = var.aws_region }
      ]
    }
  ])
}

# ---------------------------------------------------------
# ECS SERVICE
# ---------------------------------------------------------
resource "aws_ecs_service" "main_service" {
  name            = "${var.project_name}-Service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "microservicio-demo"
    container_port   = 80
  }
}
