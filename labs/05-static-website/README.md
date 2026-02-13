# Lab 05: Hosting de Web Estática con CloudFront y S3

## Objetivo

Desplegar un sitio web estático con distribución global usando Amazon S3 como origen y CloudFront como CDN. Este patrón es fundamental para entender cómo AWS sirve contenido estático de forma segura, rápida y económica.

## Arquitectura

```
                    ┌──────────────────┐
                    │     Usuario      │
                    │   (navegador)    │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │    Route 53      │  ◄── Opcional: DNS personalizado
                    │  (DNS resolver)  │      (ejemplo.com)
                    └────────┬─────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │       CloudFront CDN         │
              │  ┌────────────────────────┐  │
              │  │  Edge Locations        │  │  ◄── Caché global
              │  │  (PriceClass_100)      │  │      (NA + EU)
              │  └────────────┬───────────┘  │
              │               │              │
              │  ┌────────────┴───────────┐  │
              │  │  Origin Access Control │  │  ◄── OAC: acceso seguro al S3
              │  │  (OAC)                 │  │
              │  └────────────┬───────────┘  │
              └───────────────┼──────────────┘
                              │
                              ▼
              ┌──────────────────────────────┐
              │         S3 Bucket            │
              │  ┌────────────────────────┐  │
              │  │  index.html            │  │
              │  │  error.html            │  │
              │  │  (bloqueo público)     │  │  ◄── Sin acceso público directo
              │  └────────────────────────┘  │
              └──────────────────────────────┘

              ┌──────────────────────────────┐
              │   ACM Certificate            │  ◄── Opcional: SSL en us-east-1
              │   (us-east-1, requerido      │      para dominio personalizado
              │    por CloudFront)            │
              └──────────────────────────────┘
```

## Qué vas a aprender

- **S3 Static Hosting**: almacenamiento de objetos como origen de contenido web
- **CloudFront Distributions**: CDN global con edge locations para baja latencia
- **Origin Access Control (OAC)**: acceso seguro de CloudFront a S3 sin hacer el bucket público
- **SSL/TLS con ACM**: certificados gratuitos para HTTPS
- **DNS con Route 53**: resolución de nombres de dominio personalizado
- **Redirect HTTP a HTTPS**: forzar conexiones seguras
- **Custom Error Responses**: manejo de errores para SPAs (404 -> index.html)

## Componentes desplegados

| Componente | Servicio AWS | Notas |
|---|---|---|
| Almacenamiento | S3 Bucket | Bloqueo público activado |
| CDN | CloudFront Distribution | PriceClass_100 (NA + EU) |
| Acceso seguro | CloudFront OAC | Reemplaza a OAI (legacy) |
| Certificado SSL | ACM | Opcional, en us-east-1 |
| DNS | Route 53 | Opcional, requiere dominio |

## Nota sobre el dominio

El dominio Route 53 es **opcional**. Sin un dominio personalizado, puedes acceder al sitio directamente a través del dominio de CloudFront (ejemplo: `d1234abcd.cloudfront.net`).

Si quieres usar un dominio personalizado:
1. Registra o transfiere un dominio a Route 53 (~$12/año para `.com`)
2. Descomenta las secciones de ACM y Route 53 en `main.tf`
3. Configura la variable `domain_name`

## Requisitos previos

- AWS CLI configurado
- Terraform >= 1.0

## Despliegue

```bash
terraform init
terraform plan
terraform apply
```

Tras el despliegue, accede a la URL de CloudFront que aparece en los outputs.

## Coste estimado

**~$0.50/mes** (principalmente el almacenamiento S3).

| Servicio | Coste aproximado |
|---|---|
| S3 (almacenamiento) | ~$0.02/mes |
| CloudFront (transferencia) | Free Tier: 1 TB/mes |
| Route 53 (zona hosted) | $0.50/mes (si se usa) |
| Dominio | ~$12/año (si se compra) |
| ACM | Gratis |

Este lab es muy económico y puede dejarse activo sin preocuparse por costes elevados.
