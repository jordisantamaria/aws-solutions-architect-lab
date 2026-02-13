# Lab 03: API REST Serverless

## Objetivo

Construir una API REST serverless completa con operaciones CRUD usando API Gateway, Lambda y DynamoDB. Este patron es uno de los mas comunes en arquitecturas modernas de AWS y es fundamental para el examen de Solutions Architect.

## Arquitectura

```
                    +------------------+
                    |     Cliente      |
                    |  (curl/browser)  |
                    +--------+---------+
                             |
                    +--------+---------+
                    |   API Gateway    |
                    |   REST API       |
                    +--------+---------+
                             |
              +--------------+--------------+
              |              |              |
        GET /items    POST /items    DELETE /items/{id}
        GET /items/{id}              PUT /items/{id}
              |              |              |
              +--------------+--------------+
                             |
                    +--------+---------+
                    |     Lambda       |
                    |   (Python 3.12) |
                    +--------+---------+
                             |
                    +--------+---------+
                    |    DynamoDB      |
                    |   items table    |
                    +------------------+

  IAM Role (Lambda):
    - AWSLambdaBasicExecutionRole (CloudWatch Logs)
    - DynamoDB: PutItem, GetItem, Scan, UpdateItem, DeleteItem
```

## Que vas a aprender

- **Lambda Functions:** Funciones serverless que se ejecutan en respuesta a eventos
- **API Gateway REST API:** Servicio para crear, publicar y gestionar APIs
- **DynamoDB:** Base de datos NoSQL key-value completamente gestionada
- **IAM Roles para Lambda:** Principio de minimo privilegio para funciones Lambda
- **Lambda Proxy Integration:** API Gateway pasa el request completo a Lambda
- **Stages y Deployments:** Gestion de versiones de la API

## Prerequisitos

- Lab 00 completado (backend remoto)

## Operaciones CRUD

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| GET | /items | Listar todos los items |
| POST | /items | Crear un nuevo item |
| GET | /items/{id} | Obtener un item por ID |
| PUT | /items/{id} | Actualizar un item |
| DELETE | /items/{id} | Eliminar un item |

## Pasos para Deploy

### 1. Desplegar la infraestructura

```bash
cd labs/03-serverless-api

# Inicializar
terraform init

# Revisar el plan
terraform plan

# Aplicar
terraform apply
```

### 2. Obtener la URL de la API

```bash
export API_URL=$(terraform output -raw api_gateway_invoke_url)
echo $API_URL
```

### 3. Test con curl

```bash
# Crear un item
curl -X POST "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{"name": "Mi primer item", "description": "Creado desde el lab 03"}'

# Listar todos los items
curl "$API_URL/items" | jq .

# Obtener un item por ID (reemplaza <id> con el ID del item creado)
curl "$API_URL/items/<id>" | jq .

# Actualizar un item
curl -X PUT "$API_URL/items/<id>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Item actualizado", "description": "Modificado"}'

# Eliminar un item
curl -X DELETE "$API_URL/items/<id>"
```

---

## Conceptos Clave para el Examen

- **Lambda Pricing:** Cobro por numero de requests y duracion (GB-segundo). 1M requests/mes gratis.
- **DynamoDB Pricing:** Modo On-Demand cobra por lectura/escritura. 25 WCU + 25 RCU gratis.
- **API Gateway:** Limite de 10,000 requests/segundo por defecto (soft limit).
- **Lambda Concurrency:** Limite de 1000 ejecuciones concurrentes por defecto por region.
- **Lambda Proxy Integration:** API Gateway pasa todo el HTTP request como evento a Lambda.
- **DynamoDB Partition Key:** Elegir una buena partition key es crucial para el rendimiento.

## Coste Estimado

| Recurso | Coste |
|---------|-------|
| Lambda | Free Tier: 1M requests + 400,000 GB-seg/mes |
| API Gateway | Free Tier: 1M requests/mes (12 meses) |
| DynamoDB (On-Demand) | Free Tier: 25 WCU + 25 RCU |

> **Total estimado: Gratis** dentro del Free Tier para uso de laboratorio. Perfecto para practicar sin costes.

## Limpieza

```bash
terraform destroy
```

## Estructura de Ficheros

```
03-serverless-api/
  main.tf              # DynamoDB, Lambda, API Gateway, IAM
  variables.tf         # Variables de entrada
  outputs.tf           # Valores de salida
  backend.tf           # Configuracion del backend remoto
  lambda/
    handler.py         # Codigo Python del Lambda handler
  README.md            # Este fichero
```
