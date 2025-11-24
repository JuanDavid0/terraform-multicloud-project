# 🎓 Guía de Presentación - Proyecto Terraform Multi-Cloud

## 📚 Orden Recomendado para Explicar el Proyecto

---

## **PARTE 1: Introducción y Contexto (5-7 minutos)**

### 1.1 Problema que Resuelve
**"¿Por qué existe este proyecto?"**

- **Escenario Real:** Empresa con infraestructura en múltiples nubes (AWS + Azure)
- **Desafío:** Mantener sincronizados los datos entre ambas nubes
- **Solución:** Infraestructura como Código (IaC) con Terraform + sincronización automática

### 1.2 Arquitectura General (Diagrama en Pizarra)

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Application Load     │
              │     Balancer          │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   ECS Fargate         │
              │  (Flask App)          │
              └──────┬───────┬────────┘
                     │       │
        ┌────────────┘       └────────────┐
        ▼                                 ▼
┌───────────────┐                 ┌──────────────┐
│   DynamoDB    │──Stream────┐    │   S3 Bucket  │──Event──┐
└───────────────┘            │    └──────────────┘         │
                             ▼                              ▼
                    ┌─────────────────┐          ┌──────────────────┐
                    │ Lambda Sync     │          │  Lambda S3 Sync  │
                    │   DynamoDB      │          │                  │
                    └────────┬────────┘          └────────┬─────────┘
                             │                            │
                             ▼                            ▼
                    ┌─────────────────┐          ┌──────────────────┐
                    │  Azure Cosmos   │          │  Azure Blob      │
                    │      DB         │          │    Storage       │
                    └─────────────────┘          └──────────────────┘
```

**Explicar:**
- Usuario → ALB → ECS → Guardar en DynamoDB/S3
- DynamoDB/S3 → Trigger → Lambda → Replica a Azure

---

## **PARTE 2: Fundamentos de Terraform (8-10 minutos)**

### 2.1 ¿Qué es Terraform?
**Código a mostrar: `providers.tf`**

```terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

**Explicar:**
- Terraform = Herramienta para definir infraestructura con código
- `required_providers` = Conectores a las nubes (plugins)
- `version` = Control de versiones para estabilidad
- **Ventaja:** Un solo lenguaje (HCL) para múltiples nubes

### 2.2 Variables de Entrada
**Código a mostrar: `variables.tf`**

```terraform
variable "proyecto_nombre" {
  description = "Nombre base del proyecto"
  type        = string
  default     = "RetoFinalCloud"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

**Explicar:**
- Variables = Parámetros reutilizables
- `default` = Valor por defecto (se puede sobrescribir)
- `type` = Validación de tipos de datos
- **Analogía:** Como variables en programación, pero para infraestructura

### 2.3 Outputs (Salidas)
**Código a mostrar: `outputs.tf`**

```terraform
output "alb_dns_name" {
  description = "URL pública del Application Load Balancer"
  value       = module.aws_alb.alb_dns_name
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = module.aws_database.dynamodb_table_name
}
```

**Explicar:**
- Outputs = Valores importantes que Terraform expone
- Se usan para obtener URLs, IDs, nombres de recursos creados
- **Demo en vivo:** `terraform output alb_dns_name`

---

## **PARTE 3: Modularización (10-12 minutos)**

### 3.1 ¿Por Qué Módulos?
**Mostrar la estructura de carpetas:**

```
modules/
├── aws/
│   ├── networking/    → VPC, Subnets, NAT
│   ├── security/      → Security Groups
│   ├── alb/           → Load Balancer
│   ├── compute/       → ECR, ECS, Fargate
│   ├── database/      → DynamoDB
│   ├── storage/       → S3
│   └── lambda/        → Funciones Lambda
└── azure/
    ├── storage/       → Blob Storage
    └── database/      → Cosmos DB
```

**Explicar:**
- Cada módulo = Responsabilidad única
- **Ventaja 1:** Reutilización (puedes usar el módulo en otro proyecto)
- **Ventaja 2:** Mantenimiento (cambiar una parte sin romper todo)
- **Ventaja 3:** Colaboración (equipos diferentes trabajando en módulos distintos)

### 3.2 Orquestación en `main.tf`
**Código a mostrar: `main.tf` (completo)**

```terraform
# Azure Resource Group (pre-requisito)
resource "azurerm_resource_group" "rg_azure" {
  name     = "${var.proyecto_nombre}-RG"
  location = var.azure_location
}

# Módulo 1: Networking (base)
module "aws_networking" {
  source = "./modules/aws/networking"
  
  project_name         = var.proyecto_nombre
  vpc_cidr             = var.aws_vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Módulo 2: Security (depende de networking)
module "aws_security" {
  source = "./modules/aws/security"
  
  project_name = var.proyecto_nombre
  vpc_id       = module.aws_networking.vpc_id  # ← DEPENDENCIA
}
```

**Explicar:**
- `main.tf` = Director de orquesta
- `source` = Ubicación del módulo
- `module.aws_networking.vpc_id` = Referencia entre módulos (dependencias)
- **Orden de ejecución:** Terraform calcula automáticamente el orden correcto

---

## **PARTE 4: Módulos AWS en Detalle (15-20 minutos)**

### 4.1 Networking Module
**Archivo:** `modules/aws/networking/main.tf`

**Conceptos clave a explicar:**

```terraform
# VPC (Red Virtual Privada)
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr        # 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Subnets Públicas (acceso a internet)
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

# NAT Gateway (salida a internet para subnets privadas)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
}
```

**Explicar con analogía:**
- **VPC** = Tu edificio privado en AWS
- **Subnets públicas** = Pisos con balcón (acceso directo a internet)
- **Subnets privadas** = Pisos internos (sin acceso directo)
- **NAT Gateway** = Puerta de salida controlada para pisos internos
- **Internet Gateway** = Puerta de entrada/salida para pisos con balcón

**Mostrar outputs:**
```terraform
output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
```

### 4.2 Security Module
**Archivo:** `modules/aws/security/main.tf`

```terraform
# Security Group para ALB (acceso público)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-ALB-SG"
  description = "Permitir tráfico HTTP desde internet"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Todo internet
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para ECS (solo acepta tráfico del ALB)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ECS-SG"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "Traffic from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Solo ALB
  }
}
```

**Explicar con analogía:**
- **Security Groups** = Guardias de seguridad en cada puerta
- **ALB SG** = Guardia de entrada principal (acepta visitantes de internet)
- **ECS SG** = Guardia interno (solo acepta visitantes que pasaron por el guardia principal)
- **Principio de defensa en capas:** Múltiples niveles de seguridad

### 4.3 ALB Module
**Archivo:** `modules/aws/alb/main.tf`

```terraform
# Application Load Balancer
resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-ALB"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
}

# Target Group (destinos del tráfico)
resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.project_name}-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Para Fargate
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
  }
}

# Listener (escucha peticiones)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
```

**Explicar:**
- **ALB** = Recepcionista inteligente (distribuye peticiones)
- **Target Group** = Lista de servidores disponibles
- **Health Check** = Chequeo de salud cada 60 segundos
- **Listener** = Oído atento al puerto 80

### 4.4 Compute Module (ECS Fargate)
**Archivo:** `modules/aws/compute/main.tf`

```terraform
# ECR Repository (almacén de imágenes Docker)
resource "aws_ecr_repository" "repos" {
  count = 3
  name  = "${var.project_name}-service-${count.index + 1}"
}

# ECS Cluster (orquestador de contenedores)
resource "aws_ecs_cluster" "main_cluster" {
  name = "${var.project_name}-Cluster"
}

# Task Definition (plantilla del contenedor)
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-Task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"   # 0.25 vCPU
  memory                   = "512"   # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([{
    name  = "app-container"
    image = "${aws_ecr_repository.repos[0].repository_url}:latest"
    
    environment = [
      { name = "DYNAMO_TABLE", value = var.dynamodb_table_name },
      { name = "S3_BUCKET", value = var.s3_bucket_name },
      { name = "AWS_REGION", value = data.aws_region.current.name }
    ]
    
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# ECS Service (mantiene 2 réplicas corriendo)
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-Service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2  # 2 contenedores
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app-container"
    container_port   = 80
  }
}
```

**Explicar:**
- **ECR** = Docker Hub privado de AWS
- **ECS Cluster** = Parqueadero de contenedores
- **Task Definition** = Receta de cómo crear el contenedor
- **ECS Service** = Gerente que mantiene 2 copias corriendo siempre
- **Fargate** = Serverless (AWS administra los servidores)

### 4.5 Database Module (DynamoDB)
**Archivo:** `modules/aws/database/main.tf`

```terraform
resource "aws_dynamodb_table" "main_table" {
  name           = "${var.project_name}-TablaUsuarios"
  billing_mode   = "PAY_PER_REQUEST"  # Sin capacidad fija
  hash_key       = "id"
  stream_enabled = true  # ← CLAVE para Lambda
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "id"
    type = "S"  # String
  }
}
```

**Explicar:**
- **DynamoDB** = Base de datos NoSQL (clave-valor)
- **PAY_PER_REQUEST** = Pagas solo lo que usas
- **stream_enabled** = Genera eventos cuando hay cambios
- **stream_view_type** = Qué datos enviar en el evento (antes y después)

### 4.6 Storage Module (S3)
**Archivo:** `modules/aws/storage/main.tf`

```terraform
# Sufijo random para nombre único
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# S3 Bucket
resource "aws_s3_bucket" "main_bucket" {
  bucket        = "${lower(var.project_name)}-bucket-${random_string.bucket_suffix.result}"
  force_destroy = true
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.main_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC Endpoint (acceso privado sin internet)
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.private_route_table_id]
}
```

**Explicar:**
- **S3** = Almacenamiento de archivos escalable
- **random_string** = Garantiza nombre único global
- **force_destroy** = Permite borrar bucket con archivos (útil para testing)
- **VPC Endpoint** = Túnel privado S3 ↔ VPC (sin salir a internet)

### 4.7 Lambda Module (Sincronización)
**Archivo:** `modules/aws/lambda/main.tf`

```terraform
# Empaquetar código Python
data "archive_file" "lambda_dynamo_zip" {
  type        = "zip"
  source_file = "${path.root}/app/lambda/lambda_code/dynamo_sync.py"
  output_path = "${path.module}/dynamo_sync.zip"
}

# Lambda Function para DynamoDB → Cosmos
resource "aws_lambda_function" "dynamo_sync" {
  filename         = data.archive_file.lambda_dynamo_zip.output_path
  function_name    = "${var.project_name}-SyncDynamo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "dynamo_sync.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  
  environment {
    variables = {
      COSMOS_ENDPOINT = var.cosmos_endpoint
      COSMOS_KEY      = var.cosmos_key
    }
  }
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
}

# Trigger: DynamoDB Stream → Lambda
resource "aws_lambda_event_source_mapping" "dynamo_trigger" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.dynamo_sync.arn
  starting_position = "LATEST"
  enabled           = true
}
```

**Explicar:**
- **archive_file** = Empaqueta Python en .zip
- **Lambda** = Función serverless (se ejecuta solo cuando es necesaria)
- **event_source_mapping** = Conexión automática DynamoDB → Lambda
- **VPC Config** = Lambda dentro de la VPC privada

---

## **PARTE 5: Módulos Azure (8-10 minutos)**

### 5.1 Azure Storage Module
**Archivo:** `modules/azure/storage/main.tf`

```terraform
resource "random_string" "azure_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "azure_sa" {
  name                     = "${lower(var.project_name)}sa${random_string.azure_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "azure_container" {
  name                  = "replica-archivos"
  storage_account_name  = azurerm_storage_account.azure_sa.name
  container_access_type = "private"
}
```

**Explicar:**
- **Storage Account** = Similar a S3, pero de Azure
- **LRS** = Locally Redundant Storage (3 copias en misma región)
- **Container** = Carpeta dentro del Storage Account

### 5.2 Azure Database Module (Cosmos DB)
**Archivo:** `modules/azure/database/main.tf`

```terraform
resource "azurerm_cosmosdb_account" "cosmos_acc" {
  name                = "${lower(var.project_name)}-cosmos-${random_string.cosmos_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  
  consistency_policy {
    consistency_level = "Session"
  }
  
  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "cosmos_db" {
  name                = "ReplicaDB"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
}

resource "azurerm_cosmosdb_sql_container" "cosmos_container" {
  name                = "TablaUsuariosReplica"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
  database_name       = azurerm_cosmosdb_sql_database.cosmos_db.name
  partition_key_paths = ["/id"]
  throughput          = 400
}
```

**Explicar:**
- **Cosmos DB** = Base de datos NoSQL multi-región de Azure (equivalente a DynamoDB)
- **GlobalDocumentDB** = Tipo compatible con MongoDB/SQL
- **Consistency Level "Session"** = Balance entre rendimiento y consistencia
- **partition_key_paths** = Cómo se distribuyen los datos (igual que hash_key)

---

## **PARTE 6: Flujo de Sincronización (10-12 minutos)**

### 6.1 Código Lambda DynamoDB Sync
**Archivo:** `app/lambda/lambda_code/dynamo_sync.py`

**Mostrar fragmentos clave:**

```python
import json
import os
import urllib3

COSMOS_ENDPOINT = os.environ['COSMOS_ENDPOINT']
COSMOS_KEY = os.environ['COSMOS_KEY']

def lambda_handler(event, context):
    for record in event['Records']:
        if record['eventName'] in ['INSERT', 'MODIFY']:
            # Extraer datos del evento DynamoDB
            dynamo_data = record['dynamodb']['NewImage']
            
            # Convertir formato DynamoDB → JSON normal
            item = {
                'id': dynamo_data['id']['S'],
                'nombre': dynamo_data['nombre']['S'],
                'email': dynamo_data['email']['S']
            }
            
            # Enviar a Cosmos DB via REST API
            url = f"{COSMOS_ENDPOINT}/dbs/ReplicaDB/colls/TablaUsuariosReplica/docs"
            headers = {
                'Content-Type': 'application/json',
                'x-ms-version': '2018-12-31',
                'authorization': generate_cosmos_auth(...)
            }
            
            http.request('POST', url, body=json.dumps(item), headers=headers)
```

**Explicar el flujo:**
1. Usuario guarda registro en DynamoDB
2. DynamoDB Stream emite evento
3. Lambda detecta evento automáticamente
4. Lambda transforma datos DynamoDB → JSON
5. Lambda envía datos a Cosmos DB via REST API

### 6.2 Código Lambda S3 Sync
**Archivo:** `app/lambda/lambda_code/s3_sync.py`

```python
import boto3
import os
import urllib3
from urllib.parse import unquote_plus

s3 = boto3.client('s3')
AZURE_SAS_URL = os.environ['AZURE_SAS_URL']

def lambda_handler(event, context):
    for record in event['Records']:
        # Obtener info del archivo subido
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        # Descargar archivo de S3
        s3.download_file(bucket, key, f'/tmp/{key}')
        
        # Leer archivo
        with open(f'/tmp/{key}', 'rb') as f:
            file_data = f.read()
        
        # Subir a Azure Blob Storage
        blob_url = f"{AZURE_SAS_URL}/{key}"
        http.request('PUT', blob_url, body=file_data, headers={
            'x-ms-blob-type': 'BlockBlob'
        })
```

**Explicar el flujo:**
1. Usuario sube archivo a S3
2. S3 emite notificación de evento
3. Lambda descarga archivo a `/tmp/`
4. Lambda sube archivo a Azure Blob Storage
5. Archivo queda replicado en ambas nubes

---

## **PARTE 7: Aplicación Flask (5-7 minutos)**

### 7.1 Microservicio
**Archivo:** `app/microservice/microservice_app.py`

```python
from flask import Flask, render_template_string, request
import boto3
import os

app = Flask(__name__)

# Conexión a AWS
dynamodb = boto3.resource('dynamodb', region_name=os.environ['AWS_REGION'])
table = dynamodb.Table(os.environ['DYNAMO_TABLE'])

s3 = boto3.client('s3', region_name=os.environ['AWS_REGION'])
BUCKET = os.environ['S3_BUCKET']

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        if 'nombre' in request.form:
            # Guardar usuario en DynamoDB
            table.put_item(Item={
                'id': str(uuid.uuid4()),
                'nombre': request.form['nombre'],
                'email': request.form['email']
            })
        
        elif 'archivo' in request.files:
            # Subir archivo a S3
            archivo = request.files['archivo']
            s3.upload_fileobj(archivo, BUCKET, archivo.filename)
    
    return render_template_string(HTML_TEMPLATE)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

**Explicar:**
- Flask = Framework web ligero de Python
- Dos funciones: guardar usuarios (DynamoDB) y subir archivos (S3)
- Variables de entorno inyectadas por ECS Task Definition
- Todo se activa automáticamente con las Lambdas

---

## **PARTE 8: Comandos de Terraform (5 minutos)**

### 8.1 Ciclo de Vida Completo

```powershell
# 1. Inicializar (descargar providers y módulos)
terraform init

# 2. Formatear código
terraform fmt -recursive

# 3. Validar sintaxis
terraform validate

# 4. Planificar cambios (preview)
terraform plan

# 5. Aplicar cambios (crear infraestructura)
terraform apply -auto-approve

# 6. Ver outputs
terraform output alb_dns_name

# 7. Destruir todo
terraform destroy -auto-approve
```

**Explicar cada comando:**
- `init` = Descargar dependencias (solo la primera vez)
- `fmt` = Auto-formatear código
- `validate` = Verificar errores de sintaxis
- `plan` = Mostrar qué se va a crear/modificar/eliminar
- `apply` = Ejecutar los cambios
- `output` = Ver valores importantes
- `destroy` = Eliminar toda la infraestructura

---

## **PARTE 9: Demo en Vivo (5-7 minutos)**

### 9.1 Despliegue Completo

```powershell
# Paso 1: Desplegar infraestructura
terraform apply -auto-approve

# Paso 2: Obtener URL del ECR
terraform output ecr_repo_urls

# Paso 3: Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_URL>

# Paso 4: Construir y subir imagen
cd app/microservice
docker build -t reto-app .
docker tag reto-app:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# Paso 5: Estabilizar servicio
terraform apply -auto-approve

# Paso 6: Obtener URL de la app
terraform output alb_dns_name
```

### 9.2 Pruebas

1. **Abrir navegador** → URL del ALB
2. **Registrar usuario** → Verificar en DynamoDB y Cosmos DB
3. **Subir archivo** → Verificar en S3 y Azure Blob Storage

---

## **PARTE 10: Ventajas y Lecciones Aprendidas (3-5 minutos)**

### 10.1 Ventajas del Proyecto

✅ **Multi-Cloud:** No vendor lock-in, flexibilidad  
✅ **IaC:** Infraestructura versionada, replicable, auditable  
✅ **Modular:** Fácil de mantener, reutilizable, escalable  
✅ **Automatización:** Sincronización automática entre nubes  
✅ **Serverless:** Lambdas y Fargate (sin administrar servidores)  
✅ **Alta Disponibilidad:** 2 réplicas de ECS, 2 AZs, multi-región  

### 10.2 Buenas Prácticas Aplicadas

1. **Variables reutilizables** (DRY - Don't Repeat Yourself)
2. **Outputs para integraciones** entre módulos
3. **Security Groups restrictivos** (principio de menor privilegio)
4. **VPC Endpoints** (reduce costos de NAT)
5. **IAM Roles específicos** (no permisos de admin globales)
6. **Nombres dinámicos** con sufijos random (evitar colisiones)

---

## **PARTE 11: Preguntas Frecuentes**

### ¿Por qué no ARM templates o CloudFormation?
- **Terraform es multi-cloud**, ARM/CFN solo funcionan en una nube
- **HCL es más legible** que JSON/YAML
- **Ecosistema maduro** con 3000+ providers

### ¿Por qué módulos en lugar de un solo archivo?
- **Reusabilidad:** Puedes usar el módulo de networking en otro proyecto
- **Testing:** Puedes probar cada módulo independientemente
- **Colaboración:** Equipos diferentes trabajan en módulos diferentes

### ¿Por qué Fargate y no EC2?
- **Serverless:** No administras servidores
- **Escalado automático:** Paga solo lo que usas
- **Seguridad:** AWS parchea el SO automáticamente

### ¿Cómo manejo secretos?
- **Buena práctica:** Usar AWS Secrets Manager o Azure Key Vault
- **En este proyecto:** Variables de entorno (solo para demo)

---

## **📊 Resumen Ejecutivo**

| Concepto | Valor |
|----------|-------|
| Líneas de código | ~1,500 |
| Módulos | 9 (7 AWS + 2 Azure) |
| Recursos creados | 52 |
| Regiones | 2 (us-east-1, westus) |
| Proveedores | 4 (AWS, Azure, Random, Archive) |
| Tiempo de despliegue | ~8-10 minutos |
| Costo por hora | ~$0.50 - $1.00 USD |

---

## **🎯 Conclusión**

Este proyecto demuestra:
- ✅ Dominio de Terraform avanzado (módulos, dependencias, multi-cloud)
- ✅ Conocimiento de AWS (VPC, ECS, Lambda, DynamoDB, S3)
- ✅ Conocimiento de Azure (Storage, Cosmos DB)
- ✅ Arquitectura de microservicios
- ✅ Automatización y DevOps
- ✅ Buenas prácticas de IaC

**Total:** ~60-75 minutos de presentación + 10-15 min de preguntas = **1:15 - 1:30 horas**

---

## **🔗 Recursos Adicionales**

- Terraform Docs: https://registry.terraform.io/
- AWS Well-Architected: https://aws.amazon.com/architecture/well-architected/
- Azure Architecture Center: https://learn.microsoft.com/en-us/azure/architecture/

---

**¡Éxito en tu presentación! 🚀**
