# Lab 00: Setup Inicial

## Descripcion

Este laboratorio te guia a traves de la configuracion inicial necesaria para trabajar con AWS y Terraform. Configuraras las herramientas base y crearas la infraestructura necesaria para gestionar el estado de Terraform de forma remota.

## Requisitos Previos

- Cuenta de AWS (Free Tier es suficiente para empezar)
- Terminal (bash/zsh)
- Editor de texto (VS Code recomendado)

---

## Paso 1: Instalar AWS CLI v2

### macOS

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Verificar instalacion

```bash
aws --version
```

---

## Paso 2: Configurar Credenciales de AWS

### Opcion A: Configuracion basica

```bash
aws configure
# AWS Access Key ID: <tu-access-key>
# AWS Secret Access Key: <tu-secret-key>
# Default region name: eu-west-1
# Default output format: json
```

### Opcion B: Usar profiles (recomendado)

```bash
aws configure --profile aws-lab
# Introduce tus credenciales

# Para usar el profile:
export AWS_PROFILE=aws-lab

# Verificar que funciona:
aws sts get-caller-identity --profile aws-lab
```

> **Buena practica:** Nunca uses las credenciales del usuario root. Crea un usuario IAM con permisos de administrador para los laboratorios.

---

## Paso 3: Instalar Terraform

### macOS (con Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Linux

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Verificar instalacion

```bash
terraform version
```

---

## Paso 4: Crear Backend Remoto para Terraform State

### Por que un backend remoto?

Por defecto, Terraform guarda el estado (`terraform.tfstate`) en un fichero local. Esto tiene varios problemas:

1. **State locking:** Sin locking, si dos personas ejecutan `terraform apply` a la vez, pueden corromper el estado. DynamoDB proporciona locking distribuido.
2. **Colaboracion:** Con el estado en local, cada miembro del equipo tiene su propia version. S3 centraliza el estado para todo el equipo.
3. **Seguridad:** El fichero de estado contiene informacion sensible (IPs, ARNs, a veces passwords). S3 permite cifrado y control de acceso con IAM.
4. **Durabilidad:** S3 ofrece 99.999999999% de durabilidad. Un disco local puede fallar.
5. **Versionado:** Con versioning en S3, puedes recuperar estados anteriores si algo sale mal.

### Deploy del backend

```bash
cd labs/00-setup

# Inicializar Terraform (backend local para este primer paso)
terraform init

# Revisar el plan
terraform plan -var="project_name=aws-lab" -var="environment=dev"

# Aplicar
terraform apply -var="project_name=aws-lab" -var="environment=dev"
```

### Verificar

```bash
# Verificar que el bucket existe
aws s3 ls | grep aws-lab

# Verificar la tabla DynamoDB
aws dynamodb list-tables
```

---

## Paso 5: Configurar el Backend en los Siguientes Labs

Una vez creado el bucket y la tabla, los siguientes laboratorios usaran este backend. Veras un fichero `backend.tf` en cada lab con la configuracion correspondiente.

```hcl
terraform {
  backend "s3" {
    bucket         = "aws-lab-dev-terraform-state"
    key            = "lab-XX/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "aws-lab-dev-terraform-lock"
    encrypt        = true
  }
}
```

---

## Limpieza

> **Importante:** NO destruyas este lab hasta que hayas terminado todos los demas, ya que el backend remoto es necesario para el resto de laboratorios.

```bash
terraform destroy -var="project_name=aws-lab" -var="environment=dev"
```

---

## Estructura de Ficheros

```
00-setup/
  main.tf          # Recursos principales (S3 bucket, DynamoDB table)
  variables.tf     # Variables de entrada
  outputs.tf       # Valores de salida
  README.md        # Este fichero
```
