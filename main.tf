
# MAIN ORCHESTRATION FILE
# Orquesta todos los módulos de AWS y Azure



# AZURE RESOURCE GROUP

resource "azurerm_resource_group" "rg_azure" {
  name     = "${var.proyecto_nombre}-RG"
  location = var.azure_location
}


# AWS NETWORKING MODULE

module "aws_networking" {
  source = "./modules/aws/networking"

  project_name         = var.proyecto_nombre
  vpc_cidr             = var.aws_vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


# AWS SECURITY MODULE

module "aws_security" {
  source = "./modules/aws/security"

  project_name = var.proyecto_nombre
  vpc_id       = module.aws_networking.vpc_id
}


# AWS ALB MODULE

module "aws_alb" {
  source = "./modules/aws/alb"

  project_name          = var.proyecto_nombre
  vpc_id                = module.aws_networking.vpc_id
  public_subnet_ids     = module.aws_networking.public_subnet_ids
  alb_security_group_id = module.aws_security.alb_security_group_id
}


# AWS DATABASE MODULE

module "aws_database" {
  source = "./modules/aws/database"

  project_name = var.proyecto_nombre
}


# AWS STORAGE MODULE

module "aws_storage" {
  source = "./modules/aws/storage"

  project_name           = var.proyecto_nombre
  aws_region             = var.aws_region
  vpc_id                 = module.aws_networking.vpc_id
  private_route_table_id = module.aws_networking.private_route_table_id
}


# AZURE STORAGE MODULE

module "azure_storage" {
  source = "./modules/azure/storage"

  project_name        = var.proyecto_nombre
  resource_group_name = azurerm_resource_group.rg_azure.name
  location            = azurerm_resource_group.rg_azure.location
}


# AZURE DATABASE MODULE

module "azure_database" {
  source = "./modules/azure/database"

  project_name        = var.proyecto_nombre
  resource_group_name = azurerm_resource_group.rg_azure.name
  location            = azurerm_resource_group.rg_azure.location
}


# AWS LAMBDA MODULE

module "aws_lambda" {
  source = "./modules/aws/lambda"

  project_name                    = var.proyecto_nombre
  dynamo_sync_code_path           = "${path.root}/app/lambda/lambda_code/dynamo_sync.py"
  s3_sync_code_path               = "${path.root}/app/lambda/lambda_code/s3_sync.py"
  private_subnet_ids              = module.aws_networking.private_subnet_ids
  ecs_security_group_id           = module.aws_security.ecs_security_group_id
  dynamodb_stream_arn             = module.aws_database.dynamodb_stream_arn
  cosmos_endpoint                 = module.azure_database.cosmos_account_endpoint
  cosmos_primary_key              = module.azure_database.cosmos_account_primary_key
  azure_storage_connection_string = module.azure_storage.storage_account_primary_connection_string
  azure_storage_account_name      = module.azure_storage.storage_account_name
  azure_container_name            = module.azure_storage.container_name
  s3_bucket_id                    = module.aws_storage.s3_bucket_id
  s3_bucket_arn                   = module.aws_storage.s3_bucket_arn
}


# AWS COMPUTE MODULE (ECS/Fargate)

module "aws_compute" {
  source = "./modules/aws/compute"

  project_name          = var.proyecto_nombre
  aws_region            = var.aws_region
  ecr_repository_count  = 3
  container_image       = "324315783637.dkr.ecr.us-east-1.amazonaws.com/retofinalcloud-service-1:latest"
  dynamodb_table_name   = module.aws_database.dynamodb_table_name
  s3_bucket_name        = module.aws_storage.s3_bucket_name
  private_subnet_ids    = module.aws_networking.private_subnet_ids
  ecs_security_group_id = module.aws_security.ecs_security_group_id
  target_group_arn      = module.aws_alb.target_group_arn
}