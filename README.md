# Proyecto Terraform Multi-Cloud

Proyecto de infraestructura como código (IaC) que despliega recursos en AWS y Azure de manera coordinada, utilizando una **arquitectura modular** para máxima reutilización y mantenibilidad.

## 📋 Estructura del Proyecto (Modular)

```
terraform-multicloud-project/
├── main.tf                          # Orquestador principal de módulos
├── variables.tf                     # Variables globales
├── outputs.tf                       # Outputs principales
├── providers.tf                     # Configuración de AWS y Azure
├── .gitignore                       # Archivos excluidos de Git
│
├── modules/                         # Módulos reutilizables
│   ├── aws/
│   │   ├── networking/              # VPC, subnets, IGW, NAT, route tables
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── security/                # Security Groups
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── alb/                     # Application Load Balancer
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── compute/                 # ECR, ECS, Fargate, IAM roles
│   │   │   ��── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── database/                # DynamoDB
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── storage/                 # S3, VPC Endpoint
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── lambda/                  # Funciones de sincronización
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── azure/
│       ├── storage/                 # Storage Account, Containers
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       └── database/                # Cosmos DB
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
└── app/                             # Código de aplicaciones
    ├── microservice/                # Microservicio Python
    │   ├── microservice_app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    └── lambda/
        └── lambda_code/             # Código de funciones Lambda
            ├── dynamo_sync.py       # Sync DynamoDB → Cosmos DB
            └── s3_sync.py           # Sync S3 → Azure Blob
```

## 🎯 Ventajas de la Arquitectura Modular

✅ **Reutilización**: Cada módulo puede usarse en otros proyectos  
✅ **Mantenibilidad**: Cambios aislados por responsabilidad  
✅ **Escalabilidad**: Fácil agregar nuevos recursos  
✅ **Claridad**: Separación clara entre infraestructura y aplicaciones  
✅ **Testing**: Módulos pueden probarse independientemente

## 🚀 Requisitos Previos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Cuenta de AWS con credenciales configuradas
- Cuenta de Azure con credenciales configuradas
- AWS CLI configurado
- Azure CLI configurado

## 🔧 Configuración Inicial

### 1. Configurar credenciales de AWS

```bash
# Opción 1: Variables de entorno
export AWS_ACCESS_KEY_ID="tu-access-key"
export AWS_SECRET_ACCESS_KEY="tu-secret-key"

# Opción 2: AWS CLI
aws configure
```

### 2. Configurar credenciales de Azure

```bash
# Iniciar sesión en Azure
az login

# Verificar suscripción
az account show
```

### 3. Personalizar variables

Edita el archivo `terraform.tfvars` con tus valores específicos:

```hcl
aws_bucket_name        = "tu-bucket-unico-123"
azure_storage_account_name = "tualmacenamientounico123"
```

## 📦 Uso

### Inicializar Terraform

```bash
terraform init
```

### Validar configuración

```bash
terraform validate
```

### Ver plan de ejecución

```bash
terraform plan
```

### Aplicar cambios

```bash
terraform apply
```

### Destruir recursos

```bash
terraform destroy
```

## 📊 Descripción de Módulos

### 🔷 AWS Modules

#### `modules/aws/networking`
- **VPC** con DNS habilitado
- **2 Subnets públicas** (para ALB)
- **2 Subnets privadas** (para ECS y Lambdas)
- **Internet Gateway** para conectividad pública
- **NAT Gateway** para salida de recursos privados
- **Route Tables** con asociaciones

#### `modules/aws/security`
- **ALB Security Group**: Permite HTTP (80) desde internet
- **ECS Security Group**: Solo acepta tráfico desde ALB

#### `modules/aws/alb`
- **Application Load Balancer** público
- **Target Group** tipo IP para Fargate
- **Listener** HTTP puerto 80

#### `modules/aws/compute`
- **3 Repositorios ECR** para imágenes Docker
- **ECS Cluster** con Fargate
- **Task Definition** (256 CPU, 512 MB RAM)
- **ECS Service** con 2 réplicas
- **IAM Roles** para ejecución y tareas

#### `modules/aws/database`
- **DynamoDB Table** con billing PAY_PER_REQUEST
- **Streaming habilitado** para sincronización

#### `modules/aws/storage`
- **S3 Bucket** privado con nombre único
- **VPC Endpoint Gateway** para acceso privado desde VPC

#### `modules/aws/lambda`
- **Lambda DynamoDB Sync**: Replica cambios a Cosmos DB
- **Lambda S3 Sync**: Replica archivos a Azure Blob
- **IAM Roles** con permisos necesarios
- **Triggers** automáticos (DynamoDB Streams y S3 Events)

### 🔶 Azure Modules

#### `modules/azure/storage`
- **Storage Account** con replicación LRS
- **Container** privado para archivos replicados

#### `modules/azure/database`
- **Cosmos DB Account** con API SQL
- **Database y Container** con partición por `/id`
- Throughput de 400 RU/s

## 🔄 Cómo Funcionan los Módulos

Cada módulo es **autocontenido** con 3 archivos:

1. **`main.tf`**: Recursos de Terraform
2. **`variables.tf`**: Inputs del módulo
3. **`outputs.tf`**: Valores exportados

El archivo `main.tf` en la raíz **orquesta** todos los módulos pasando outputs como inputs:

```hcl
module "aws_networking" {
  source = "./modules/aws/networking"
  # ... variables
}

module "aws_alb" {
  source = "./modules/aws/alb"
  vpc_id = module.aws_networking.vpc_id  # ← Output del módulo networking
  # ...
}
```

## 🔗 Dependencias entre Módulos

```
Networking → Security, ALB, Storage
Security → ALB, Compute, Lambda
ALB → Compute
Database → Lambda
Storage → Lambda
Azure Storage → Lambda
Azure Database → Lambda
```

## 🔒 Seguridad

- **NUNCA** subir `terraform.tfvars` a Git
- Las credenciales deben estar en variables de entorno o archivos locales
- Usar IAM roles y Managed Identities cuando sea posible
- Revisar outputs sensibles (marcados como `sensitive = true`)

## 📝 Notas

- Los nombres de buckets S3 deben ser únicos globalmente
- Las cuentas de almacenamiento de Azure solo permiten minúsculas y números
- Asegúrate de tener cuotas suficientes en ambas nubes

## 🤝 Contribuciones

Este es un proyecto educativo para la asignatura Electiva I Cloud Computing.

## 📄 Licencia

Proyecto académico - SEMESTRE 9
