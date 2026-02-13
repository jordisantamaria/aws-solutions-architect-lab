# Lab 02: Web Server con Alta Disponibilidad

## Objetivo

Desplegar un web server con alta disponibilidad usando un Application Load Balancer (ALB) con Auto Scaling Group (ASG) y instancias EC2 en subnets privadas. Este patron es fundamental para cualquier aplicacion web en produccion.

## Arquitectura

```
                         +------------------+
                         |    INTERNET      |
                         +--------+---------+
                                  |
                    +-------------+-------------+
                    |  Application Load Balancer |
                    |   (Public Subnets)         |
                    +-------------+-------------+
                          |               |
                    +-----+-----+   +-----+-----+
                    | Target    |   | Target    |
                    | Group     |   | Group     |
                    +-----+-----+   +-----+-----+
                          |               |
              +-----------+---+   +-------+-----------+
              | EC2 (nginx)   |   | EC2 (nginx)       |
              | Private Sub 1 |   | Private Sub 2     |
              | AZ-1          |   | AZ-2              |
              +---------------+   +-------------------+
                          |               |
                    +-----+-----+   +-----+-----+
                    |  Auto Scaling Group         |
                    |  Min: 2 | Max: 4 | Des: 2  |
                    +-----------------------------+

  Security Groups:
    ALB-SG:  Inbound 80 from 0.0.0.0/0
    EC2-SG:  Inbound 80 from ALB-SG only
```

## Que vas a aprender

- **Launch Templates:** Plantillas reutilizables para la configuracion de instancias EC2
- **Application Load Balancer (ALB):** Distribucion de trafico a nivel de capa 7 (HTTP/HTTPS)
- **Target Groups:** Agrupacion logica de targets (EC2) con health checks
- **Health Checks:** Verificacion automatica de la salud de las instancias
- **Auto Scaling Group (ASG):** Escalado automatico basado en demanda
- **Scaling Policies:** Politicas para escalar basandose en metricas (CPU, requests, etc.)
- **User Data:** Scripts de inicializacion ejecutados al arrancar la instancia

## Prerequisitos

- Lab 00 completado (backend remoto)
- Lab 01 completado (VPC y subnets)

## Pasos para Deploy

### 1. Verificar que Lab 01 esta desplegado

```bash
cd ../01-vpc-networking
terraform output
# Deberias ver VPC ID, subnet IDs, etc.
```

### 2. Desplegar el web server

```bash
cd ../02-web-server

# Inicializar
terraform init

# Revisar el plan
terraform plan

# Aplicar
terraform apply
```

### 3. Verificar el ALB

```bash
# Obtener el DNS del ALB
terraform output alb_dns_name

# Acceder desde el navegador o curl
curl http://$(terraform output -raw alb_dns_name)
```

Deberias ver una pagina HTML mostrando el instance ID y la Availability Zone. Si refrescas varias veces, veras como el trafico se distribuye entre las instancias.

### 4. Test de Scaling

```bash
# Verificar instancias actuales
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw asg_name)

# Para probar el escalado, puedes generar carga con herramientas como:
# ab -n 100000 -c 100 http://<alb-dns>/
# o usar stress-ng en las instancias
```

---

## Conceptos Clave para el Examen

- **ALB vs NLB:** ALB opera en capa 7 (HTTP), NLB en capa 4 (TCP). ALB puede enrutar por path/host.
- **Cross-Zone Load Balancing:** ALB lo tiene habilitado por defecto, distribuyendo trafico uniformemente entre AZs.
- **Health Checks:** Si una instancia falla el health check, el ALB deja de enviarle trafico y el ASG la reemplaza.
- **Scaling Policies:** Target Tracking es la mas sencilla (mantener CPU al 60%). Step Scaling permite respuestas mas granulares.

## Coste Estimado

| Recurso | Coste |
|---------|-------|
| ALB | ~$0.0252/hora (~$0.60/dia) |
| EC2 t3.micro x2 | ~$0.0116/hora x2 (~$0.56/dia) |
| NAT Gateway (del Lab 01) | ~$1.15/dia |
| Data transfer | Variable |

> **Total estimado: ~$2-3/dia.** Recuerda hacer `terraform destroy` cuando no estes practicando.

## Limpieza

```bash
# Destruir este lab primero
terraform destroy

# Luego puedes destruir Lab 01 si ya no lo necesitas
cd ../01-vpc-networking
terraform destroy
```

## Estructura de Ficheros

```
02-web-server/
  main.tf          # ALB, ASG, Launch Template, Security Groups
  variables.tf     # Variables de entrada
  outputs.tf       # Valores de salida
  backend.tf       # Configuracion del backend remoto
  user_data.sh     # Script de inicializacion de las instancias
  README.md        # Este fichero
```
