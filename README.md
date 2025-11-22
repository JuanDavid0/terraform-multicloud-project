# Proyecto Terraform Multi-Cloud

Proyecto de infraestructura como código (IaC) que despliega recursos en AWS y Azure de manera coordinada.

## 📋 Estructura del Proyecto

```
terraform-multicloud-project/
├── main.tf              # Configuración principal
├── variables.tf         # Variables reutilizables
├── outputs.tf           # Valores de salida
├── providers.tf         # Configuración de AWS y Azure
├── terraform.tfvars     # Valores de variables (NO subir a Git)
└── modules/             # Módulos reutilizables
    ├── aws-networking/
    ├── aws-compute/
    ├── aws-database/
    ├── aws-storage/
    ├── azure-networking/
    ├── azure-compute/
    ├── azure-database/
    ├── azure-storage/
    └── lambda-sync/
```

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

## 📊 Módulos

### AWS Modules
- **aws-networking**: VPC, subnets, gateways
- **aws-compute**: Instancias EC2
- **aws-database**: RDS PostgreSQL/MySQL
- **aws-storage**: S3 buckets

### Azure Modules
- **azure-networking**: VNet, subnets, NSG
- **azure-compute**: Máquinas virtuales
- **azure-database**: Azure SQL Database
- **azure-storage**: Storage Accounts

### Lambda Sync
- Función Lambda para sincronización entre AWS S3 y Azure Blob Storage

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
