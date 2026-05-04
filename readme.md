AWS Lambda Integration

Proyecto que despliega una arquitectura serverless en AWS para recibir imágenes, almacenarlas en S3 y procesarlas en formato circular de 40x40px. Se despliega en tres entornos: `dev`, `qa` y `prod` usando Terraform Workspaces.

## Requisitos

- Terraform >= 1.0
- AWS CLI con perfil configurado
- Node.js 20.x
- npm

## Guía de Despliegue

### 1. Instalar dependencias de las Lambdas

```bash
cd lambdas/upload
npm install

cd ../crop
npm install

```

Si hay algun error en el cloudwatch por parte de /crop lo mas seguro que sea es por la biblioteca de sharp puede que tenga manuelmente para linux (lambda aws) o.o

```bash
npm install --os=linux --cpu=x64 sharp
```

### 2. Configurar credenciales AWS

```bash
aws configure --profile tu-perfil
```

### 3. Inicializar Terraform

```bash
cd iac
terraform init
```

### 4. Crear los workspaces

```bash
terraform workspace new dev
terraform workspace new qa
terraform workspace new prod
```

### 5. Desplegar un entorno

Selecciona el entorno y aplica:

```bash
terraform workspace select dev
terraform apply
```

Repite para `qa` y `prod`.

### 6. Destruir un entorno

```bash
terraform workspace select dev
terraform destroy
```

## Variables de Configuración

Crea tu arhivo `terraform.tfvars` para ajustar la configuración por entorno:

```hcl
profile = "tu-perfil"
region  = "us-east-1"
suffix  = "abc123"

config = {
  dev = {
    lambda_memory_upload  = 256
    lambda_memory_crop    = 512
    lambda_timeout_upload = 30
    lambda_timeout_crop   = 60
    throttling_rate       = 100
    throttling_burst      = 100
    log_retention         = 7
    dlq_retention         = 604800 (seg en dias : 7)
  }
  qa = {
    lambda_memory_upload  = 256
    lambda_memory_crop    = 512
    lambda_timeout_upload = 30
    lambda_timeout_crop   = 60
    throttling_rate       = 500
    throttling_burst      = 500
    log_retention         = 7
    dlq_retention         = 604800 (seg en dias : 7)
  }
  prod = {
    lambda_memory_upload  = 256
    lambda_memory_crop    = 512
    lambda_timeout_upload = 30
    lambda_timeout_crop   = 60
    throttling_rate       = 1000
    throttling_burst      = 1000
    log_retention         = 14
    dlq_retention         = 1209600 (seg en dias : 14)
  }
}
```

## Diagrama

Ver `architecture.mermaid` para el diagrama completo de la arquitectura.

<br />

En si todo esta tal cual la arquitectura inicial, lo unico que cambie fue el throttling\_rate ya que considere que 10,000 rps es mucho para un endpoint que recibe imagenes de hasta 10mb, no es una operación de alta frecuencia como un login o una búsqueda.

Tambien cada request genera una cadena de costos: invocación de Lambda, escritura en S3, mensaje en SQS e invocación de la crop-lambda.

1,000 imágenes por segundo es una capacidad suficiente para el caso de uso actual y puede incrementarse en cualquier momento modificando la variable `throttling_rate` en el `terraform.tfvars`.

Por ultimo limitar el throttling reduce la exposición ante ataques de denegación de servicio y costos inesperados.

<br />

una buena nota profeeee 

```hcl
```

