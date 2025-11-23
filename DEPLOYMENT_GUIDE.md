# 🚀 Protocolo de Resurrección (Despliegue Post-Destroy)

Sigue este orden estrictamente cuando quieras volver a levantar tu proyecto después de haber ejecutado un `terraform destroy`.

---

## 📋 Paso 1: Levantar la Infraestructura Base

Lo primero es crear la red, las bases de datos y, lo más importante, el **Repositorio ECR** vacío para poder subir la imagen.

1. Abre tu terminal en la carpeta del proyecto.
2. Ejecuta:
   ```powershell
   terraform apply -auto-approve
   ```
3. **⚠️ Nota Importante:** Al final de este comando, es posible que Terraform muestre un error en rojo diciendo que el `aws_ecs_service` falló o está "inestable".
   * **¡NO TE ASUSTES!** Es normal. Fargate está intentando arrancar pero no encuentra la imagen Docker (porque el repo está vacío). Ignora el error y sigue al paso 2.

---

## 🐳 Paso 2: Subir la Imagen Docker (Login Manual)

Ahora llenaremos el repositorio vacío con tu aplicación. Recuerda que al recrear la infraestructura, **la URL del repositorio puede cambiar**, así que no uses comandos viejos guardados.

### 2.1 Obtener la nueva URL del Repositorio:

```powershell
terraform output ecr_repo_urls
```

*(Copia la URL que sale, ejemplo: `324315...dkr.ecr.../retofinalcloud-service-1...`)*.

### 2.2 Obtener la contraseña de AWS:

```powershell
aws ecr get-login-password --region us-east-1
```

*(Copia el chorro de caracteres largo que sale en pantalla)*.

### 2.3 Login Manual en Docker:

Escribe el siguiente comando reemplazando los valores (recuerda: la URL aquí va **sin** el nombre del repo al final, solo hasta `.com`):

```powershell
docker login -u AWS -p <PEGA_LA_CONTRASEÑA_AQUI> <NUMERO_ID>.dkr.ecr.us-east-1.amazonaws.com
```

*(Debe decir: **Login Succeeded**)*.

### 2.4 Construir y Subir:

Reemplaza `<URL_COMPLETA_DEL_REPO>` con la que obtuviste en el punto 2.1.

```powershell
# Navegar a la carpeta del microservicio
cd app/microservice

# Construir
docker build -t reto-app .

# Etiquetar
docker tag reto-app:latest <URL_COMPLETA_DEL_REPO>:latest

# Subir
docker push <URL_COMPLETA_DEL_REPO>:latest

# Volver a la raíz del proyecto
cd ../..
```

---

## ✅ Paso 3: Estabilizar el Servicio

Ahora que la imagen ya existe en la nube, le decimos a Terraform que termine de configurar lo que quedó pendiente (el servicio ECS).

1. Ejecuta nuevamente:
   ```powershell
   terraform apply -auto-approve
   ```
2. Esta vez, el comando debe terminar en **verde** sin errores.

---

## 🧪 Paso 4: Validación (El momento de la verdad)

### 4.1 Obtener el link de tu aplicación:

```powershell
terraform output alb_dns_name
```

### 4.2 Probar la aplicación:

1. Abre el navegador (preferiblemente incógnito) y entra a la URL.
2. Prueba registrar un usuario (sincronización DynamoDB → Cosmos DB).
3. Prueba subir un archivo (sincronización S3 → Azure Blob Storage).

### 4.3 Verificar sincronizaciones:

**DynamoDB:**
```powershell
aws dynamodb scan --table-name RetoFinalCloud-TablaUsuarios --region us-east-1
```

**S3:**
```powershell
aws s3 ls s3://$(terraform output -raw s3_bucket_name)
```

**Azure Cosmos DB (verificar en Portal):**
- Ve a tu cuenta de Cosmos DB → Data Explorer → ReplicaDB → TablaUsuariosReplica

**Azure Blob Storage (verificar en Portal):**
- Ve a tu Storage Account → Containers → replica-archivos

---

## 🛑 Paso 5: Apagar todo (Al terminar la clase)

Para que no te cobren ni un centavo extra:

```powershell
terraform destroy -auto-approve
```

---

## 📊 Arquitectura Desplegada

Al completar todos los pasos, tendrás:

### AWS (40 recursos):
- 🌐 VPC con 4 subnets (2 públicas, 2 privadas)
- 🔒 2 Security Groups (ALB, ECS)
- ⚖️ Application Load Balancer
- 🐳 3 ECR Repositories + ECS Cluster con Fargate
- 📊 DynamoDB con streaming
- 🗄️ S3 Bucket
- ⚡ 2 Lambda Functions (sincronización automática)

### Azure (9 recursos):
- ☁️ Storage Account con Container privado
- 🌍 Cosmos DB Account + Database + Container

---

## 🔧 Solución de Problemas

### Error: "No space left on device" al construir imagen
```powershell
docker system prune -a --volumes
```

### Error: "Unauthorized" al hacer push
Repite el paso 2.2 y 2.3 (el token de AWS expira cada 12 horas).

### Error: ECS Service no se estabiliza
Verifica que la URL de la imagen en `modules/aws/compute/main.tf` coincida con la que subiste.

### Lambda Functions no se activan
Espera 2-3 minutos después del apply. Las funciones necesitan tiempo para configurarse.

---
