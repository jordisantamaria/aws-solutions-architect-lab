# Lab 01: VPC Networking

## Objetivo

Crear una VPC production-ready desde cero con subnets publicas y privadas, internet gateway, NAT gateway, tablas de rutas, NACLs y security groups. Esta es la base de red sobre la que construiremos el resto de laboratorios.

## Que vas a aprender

- **VPC:** Virtual Private Cloud, tu red aislada en AWS
- **Subnets:** Segmentar la red en publica (accesible desde internet) y privada (solo acceso interno)
- **Internet Gateway (IGW):** Puerta de enlace para que las subnets publicas accedan a internet
- **NAT Gateway:** Permite que las subnets privadas salgan a internet sin ser accesibles desde fuera
- **Route Tables:** Reglas de enrutamiento para dirigir el trafico
- **NACLs:** Network Access Control Lists, firewall stateless a nivel de subnet
- **Security Groups:** Firewall stateful a nivel de instancia/recurso

## Diagrama de Arquitectura

```
                         +------------------+
                         |    INTERNET      |
                         +--------+---------+
                                  |
                         +--------+---------+
                         | Internet Gateway |
                         +--------+---------+
                                  |
                    +-------------+-------------+
                    |                           |
           +--------+--------+        +--------+--------+
           | Public Subnet 1 |        | Public Subnet 2 |
           |   10.0.1.0/24   |        |   10.0.2.0/24   |
           |    (AZ-1)       |        |    (AZ-2)       |
           +--------+--------+        +-----------------+
                    |
              +-----+------+
              | NAT Gateway|
              +-----+------+
                    |
                    |
                    +-------------+-------------+
                    |                           |
          +---------+---------+       +---------+---------+
          | Private Subnet 1  |       | Private Subnet 2  |
          |   10.0.3.0/24     |       |   10.0.4.0/24     |
          |    (AZ-1)         |       |    (AZ-2)         |
          +-------------------+       +-------------------+

  Route Table (Public):             Route Table (Private):
    10.0.0.0/16 -> local              10.0.0.0/16 -> local
    0.0.0.0/0   -> IGW                0.0.0.0/0   -> NAT GW
```

## Pasos para Deploy

### 1. Inicializar y aplicar

```bash
cd labs/01-vpc-networking

# Inicializar (configurar backend remoto)
terraform init

# Revisar que va a crear
terraform plan

# Aplicar
terraform apply
```

### 2. Verificar la infraestructura

```bash
# Verificar VPC
aws ec2 describe-vpcs --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verificar subnets
aws ec2 describe-subnets --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verificar Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verificar NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=tag:Lab,Values=01-vpc-networking"

# Verificar Route Tables
aws ec2 describe-route-tables --filters "Name=tag:Lab,Values=01-vpc-networking"
```

### 3. Comprobar conectividad (opcional)

Lanza una instancia EC2 en la subnet publica y otra en la privada. Verifica que:
- La instancia publica tiene acceso a internet
- La instancia privada puede salir a internet (a traves del NAT Gateway) pero no es accesible desde fuera

---

## Ejercicios Extra

### Ejercicio 1: VPC Peering

Crea una segunda VPC (10.1.0.0/16) y establece peering entre ambas. Annade las rutas necesarias para que las instancias de ambas VPCs se comuniquen.

### Ejercicio 2: VPC Endpoint para S3

Crea un Gateway VPC Endpoint para S3, de forma que el trafico hacia S3 desde las subnets privadas no pase por el NAT Gateway (ahorro de costes y mejor rendimiento).

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private.id]
}
```

### Ejercicio 3: Flow Logs

Habilita VPC Flow Logs para capturar el trafico de red y enviarlo a CloudWatch Logs.

---

## Coste Estimado

| Recurso | Coste |
|---------|-------|
| VPC, Subnets, IGW, Route Tables | Gratis |
| NAT Gateway | ~$0.048/hora (~$1.15/dia) |
| NAT Gateway data processing | $0.048/GB |
| Elastic IP (asociada a NAT) | Gratis (mientras este asociada) |

> **Total estimado: ~$1/dia** principalmente por el NAT Gateway. Recuerda hacer `terraform destroy` cuando no estes practicando.

## Limpieza

```bash
terraform destroy
```

> **Importante:** Destruye siempre los recursos al terminar de practicar para evitar costes innecesarios. El NAT Gateway cobra por hora.

## Estructura de Ficheros

```
01-vpc-networking/
  main.tf          # Recursos principales (VPC, subnets, gateways, route tables, NACLs, SGs)
  variables.tf     # Variables de entrada
  outputs.tf       # Valores de salida
  backend.tf       # Configuracion del backend remoto (S3)
  README.md        # Este fichero
```
