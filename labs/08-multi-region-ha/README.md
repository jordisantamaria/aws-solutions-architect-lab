# Lab 08: Multi-Region High Availability con Failover Automatico

## Objetivo

Disenar y desplegar una arquitectura multi-region con failover automatico usando Route53, Aurora Global Database y S3 Cross-Region Replication. Este es uno de los patrones mas importantes para el examen SA.

## Arquitectura

```
                         ┌──────────────────┐
                         │    Route 53       │
                         │  Failover DNS     │
                         │                   │
                         └─────┬───────┬─────┘
                               │       │
                    PRIMARY    │       │    SECONDARY
                    (active)   │       │    (passive)
                               ▼       ▼
              ┌────────────────────┐  ┌────────────────────┐
              │   eu-west-1        │  │   us-east-1        │
              │                    │  │                    │
              │  ┌──────────────┐  │  │  ┌──────────────┐  │
              │  │     ALB      │  │  │  │     ALB      │  │
              │  └──────┬───────┘  │  │  └──────┬───────┘  │
              │         │          │  │         │          │
              │  ┌──────▼───────┐  │  │  ┌──────▼───────┐  │
              │  │     ASG      │  │  │  │     ASG      │  │
              │  │  (t3.micro)  │  │  │  │  (t3.micro)  │  │
              │  └──────┬───────┘  │  │  └──────┬───────┘  │
              │         │          │  │         │          │
              │  ┌──────▼───────┐  │  │  ┌──────▼───────┐  │
              │  │ Aurora       │◄─┼──┼──│ Aurora       │  │
              │  │ Primary      │──┼──┼─▶│ Read Replica │  │
              │  │ (writer)     │  │  │  │ (reader)     │  │
              │  └──────────────┘  │  │  └──────────────┘  │
              │                    │  │                    │
              │  ┌──────────────┐  │  │  ┌──────────────┐  │
              │  │  S3 Bucket   │──┼──┼─▶│  S3 Bucket   │  │
              │  │  (source)    │  │  │  │  (replica)   │  │
              │  └──────────────┘  │  │  └──────────────┘  │
              └────────────────────┘  └────────────────────┘
                                  ▲
                       Aurora Global Database
                       (async replication <1s)
```

## Que vas a aprender

- **Multi-Region Architecture**: desplegar infraestructura identica en dos regiones
- **Route53 Failover Routing**: DNS failover automatico basado en health checks
- **Aurora Global Database**: replicacion de base de datos entre regiones con latencia <1 segundo
- **S3 Cross-Region Replication (CRR)**: replicacion automatica de objetos entre buckets
- **DR Strategies**: diferencias entre Backup/Restore, Pilot Light, Warm Standby y Multi-Site
- **Terraform Multi-Provider**: uso de provider aliases para desplegar en multiples regiones

## Estrategias de Disaster Recovery

| Estrategia | RPO | RTO | Coste | Este Lab |
|------------|-----|-----|-------|----------|
| Backup & Restore | Horas | Horas | $ | No |
| Pilot Light | Minutos | Minutos | $$ | No |
| Warm Standby | Segundos | Minutos | $$$ | **Si** |
| Multi-Site Active/Active | ~0 | ~0 | $$$$ | No |

Este lab implementa **Warm Standby**: infraestructura minima activa en la region secundaria, lista para escalar.

## Componentes desplegados

| Recurso | Region Primary | Region Secondary |
|---------|---------------|-----------------|
| VPC + Subnets | eu-west-1 | us-east-1 |
| ALB | eu-west-1 | us-east-1 |
| ASG (t3.micro, min 1) | eu-west-1 | us-east-1 |
| Aurora Cluster | Writer | Read Replica |
| S3 Bucket | Source | CRR Replica |
| Route53 Health Check | Primary ALB | - |
| Route53 Failover | Primary record | Secondary record |

## Coste estimado

**~$8-12/dia** (infraestructura duplicada en dos regiones)

> **IMPORTANTE**: Este lab es caro por tener infraestructura activa en dos regiones. **DESTRUYE LA INFRAESTRUCTURA EN CUANTO TERMINES**.

## Como desplegar

```bash
# Inicializar Terraform
terraform init

# Ver el plan (observa los recursos en ambas regiones)
terraform plan

# Desplegar
terraform apply

# IMPORTANTE: Destruir cuando termines
terraform destroy
```

## Probar el failover

1. **Verificar que el DNS resuelve a la region primaria**:
   ```bash
   dig +short tu-dominio.ejemplo.com
   ```

2. **Simular fallo** (detener instancias en la region primaria):
   ```bash
   # El health check de Route53 detectara el fallo
   # Automaticamente redirigira el trafico a la region secundaria
   ```

3. **Verificar failover**:
   ```bash
   # Espera ~60 segundos para que Route53 detecte el fallo
   dig +short tu-dominio.ejemplo.com
   # Deberia resolver a la IP del ALB secundario
   ```

## Conceptos clave para el examen

1. **Route53 Failover**: requiere health check activo en el registro primario
2. **Aurora Global Database**: replicacion asincrona, RPO tipico <1 segundo
3. **Aurora Failover**: se puede promover la replica secundaria a primaria (unplanned failover)
4. **S3 CRR**: requiere versionado habilitado en ambos buckets, replicacion asincrona
5. **RTO vs RPO**: Recovery Time Objective vs Recovery Point Objective
6. **Multi-AZ vs Multi-Region**: Multi-AZ es HA, Multi-Region es DR

## Limpieza

```bash
# DESTRUIR INMEDIATAMENTE cuando termines
terraform destroy
```

> **Advertencia**: Verifica en la consola de AWS que todos los recursos se han eliminado en AMBAS regiones.
