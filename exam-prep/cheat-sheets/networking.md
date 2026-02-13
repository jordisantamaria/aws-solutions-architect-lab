# Networking - Cheat Sheet Rápido

## Componentes de VPC

| Componente | Descripción |
|-----------|-------------|
| **VPC** | Red virtual aislada en AWS. Defines el rango CIDR (ej: 10.0.0.0/16). Máx 5 VPCs por región (ampliable) |
| **Subnet** | Segmento de la VPC dentro de **una sola AZ**. Pública (con ruta a IGW) o privada |
| **Internet Gateway (IGW)** | Permite comunicación entre la VPC y internet. Uno por VPC. Horizontally scaled |
| **NAT Gateway** | Permite que instancias en subnets **privadas** accedan a internet (salida). Gestionado, alta disponibilidad en una AZ |
| **NAT Instance** | Igual que NAT GW pero usando una instancia EC2 (más barato, menos escalable, más gestión) |
| **Route Table** | Define las rutas de tráfico. Cada subnet se asocia a una route table |
| **Elastic IP** | IPv4 estática pública. Se asocia a instancias o NAT Gateways |
| **CIDR Block** | Rango de IPs de la VPC. Primario + hasta 4 secundarios. Mínimo /28, máximo /16 |
| **ENI** | Elastic Network Interface — NIC virtual. Se puede mover entre instancias en la misma AZ |
| **Flow Logs** | Captura tráfico IP (accept/reject) en VPC, subnet o ENI. Se envía a CloudWatch Logs o S3 |

> **Clave examen:**
> - **NAT Gateway** para alta disponibilidad → desplegar uno **por AZ**.
> - **IGW** es necesario para que una subnet sea pública (+ route table con ruta 0.0.0.0/0 → IGW + IP pública).

---

## Security Groups vs NACLs

| Característica | Security Group | Network ACL (NACL) |
|---------------|----------------|-------------------|
| **Nivel** | **Instancia** (ENI) | **Subnet** |
| **Tipo** | **Stateful** | **Stateless** |
| **Reglas** | Solo **ALLOW** | ALLOW **y DENY** |
| **Evaluación** | Todas las reglas se evalúan antes de decidir | Reglas evaluadas **en orden numérico** (primera coincidencia gana) |
| **Tráfico de retorno** | **Automático** (stateful) | Debe permitirse **explícitamente** (stateless) |
| **Default (VPC)** | Deny all inbound, Allow all outbound | Allow all inbound y outbound |
| **Default (custom)** | Deny all inbound, Allow all outbound | **Deny all** inbound y outbound |
| **Asociación** | Se asigna a instancias | Se asigna a **subnets** |
| **Cantidad** | Hasta 5 SGs por ENI | 1 NACL por subnet |

```
Internet → NACL (subnet-level) → Security Group (instance-level) → EC2 Instance
                                                                         │
EC2 Instance → Security Group (auto-allow return) → NACL (necesita regla outbound) → Internet
```

> **Regla examen:**
> - "Bloquear una IP específica" → **NACL** (puede hacer DENY explícito)
> - "Permitir tráfico entre instancias" → **Security Group** (referenciar otro SG)
> - "Stateful" = Security Group. "Stateless" = NACL.

---

## Tipos de Elastic Load Balancer (ELB)

| Característica | ALB | NLB | GLB |
|---------------|-----|-----|-----|
| **Nombre completo** | Application Load Balancer | Network Load Balancer | Gateway Load Balancer |
| **Capa OSI** | **Layer 7** (HTTP/HTTPS) | **Layer 4** (TCP/UDP/TLS) | **Layer 3** (IP) |
| **Protocolo** | HTTP, HTTPS, gRPC, WebSocket | TCP, UDP, TLS | IP (GENEVE encapsulation) |
| **Rendimiento** | Bueno | **Ultra-alto** (millones de req/s) | Alto |
| **Latencia** | ~400 ms | **~100 μs** (ultra-baja) | Variable |
| **IP estática** | No (DNS name) | **Sí** (Elastic IP por AZ) | No |
| **SSL termination** | Sí | Sí | No |
| **Routing avanzado** | **Sí** (path, host, header, query string) | No | No |
| **Sticky sessions** | Sí | No (flow hash) | No |
| **Targets** | Instancias, IPs, Lambda, containers | Instancias, IPs, ALB | Instancias, IPs (appliances) |
| **Caso de uso** | Apps web, microservicios, content routing | Gaming, IoT, ultra-baja latencia, IP estática | Firewalls, IDS/IPS, deep packet inspection |

> **Trucos examen:**
> - "Routing basado en URL path" → **ALB**
> - "IP estática" o "ultra-baja latencia" → **NLB**
> - "Inspeccionar tráfico con appliance de terceros" → **GLB**
> - "Necesito tanto IP estática como routing L7" → **NLB delante de ALB**

---

## Route 53 - Routing Policies

| Política | Descripción | Caso de uso |
|----------|-------------|-------------|
| **Simple** | Un registro, uno o más valores. Route 53 devuelve todos, cliente elige aleatoriamente | Sitio web simple sin requisitos especiales |
| **Weighted** | Distribuye tráfico según **pesos asignados** (0-255) | A/B testing, despliegue gradual (10% nuevo, 90% viejo) |
| **Latency-based** | Redirige al recurso con **menor latencia** desde el usuario | Apps multi-región, optimizar experiencia del usuario |
| **Failover** | Activo/pasivo con **health checks**. Si primario falla, redirige a secundario | DR activo-pasivo, sitios estáticos S3 de backup |
| **Geolocation** | Routing basado en la **ubicación geográfica** del usuario (continente, país) | Contenido localizado, restricciones legales por país |
| **Geoproximity** | Routing basado en distancia geográfica + **bias** para ampliar/reducir zona | Control granular de distribución de tráfico por región |
| **Multi-value answer** | Devuelve múltiples IPs **con health checks** por cada una | Balanceo simple client-side con health checking |
| **IP-based** | Routing basado en el **rango IP del cliente** (CIDR blocks) | ISPs específicos, rangos IP de oficinas corporativas |

> **Clave examen:**
> - "Menor latencia para usuarios globales" → **Latency-based**
> - "DR activo/pasivo" → **Failover**
> - "Contenido diferente según país" → **Geolocation**
> - "Despliegue gradual / canary" → **Weighted**

---

## CloudFront vs Global Accelerator

| Característica | CloudFront | Global Accelerator |
|---------------|------------|-------------------|
| **Tipo** | CDN (Content Delivery Network) | Network layer accelerator |
| **Contenido** | **Cachea contenido** en edge locations | **No cachea** — proxy a nivel de red |
| **Protocolo** | HTTP/HTTPS | TCP/UDP (cualquier protocolo) |
| **IPs** | Dominio DNS (d123.cloudfront.net) | **2 IPs Anycast estáticas** |
| **Edge Locations** | 400+ PoPs globales | Misma red de edge |
| **Caso de uso** | Contenido estático/dinámico web, streaming, APIs | Apps TCP/UDP no-HTTP, gaming, IoT, IP estática global |
| **DDoS** | AWS Shield Standard incluido | AWS Shield Standard incluido |
| **Failover** | Origin failover groups | Endpoint health checks + failover instantáneo |

> **Regla examen:**
> - "Acelerar contenido web / API / estático" → **CloudFront**
> - "IPs estáticas globales" o "protocolo no-HTTP" → **Global Accelerator**
> - "Ambos" si necesitan IP estática + contenido HTTP → **Global Accelerator delante de ALB**

---

## VPN vs Direct Connect

| Característica | Site-to-Site VPN | Direct Connect (DX) |
|---------------|------------------|---------------------|
| **Conexión** | Internet (cifrada con IPSec) | Fibra dedicada privada |
| **Tiempo de setup** | **Minutos** | **Semanas a meses** |
| **Ancho de banda** | Limitado por internet (~1.25 Gbps por túnel) | **1 Gbps, 10 Gbps, 100 Gbps** (dedicado) |
| **Latencia** | Variable (internet) | **Consistente y baja** |
| **Costo** | Menor (por hora + datos) | Mayor (puerto mensual + datos) |
| **Cifrado** | **Sí** (IPSec nativo) | **No** nativo (añadir VPN sobre DX para cifrado) |
| **Redundancia** | Dos túneles por defecto | Segundo DX o VPN backup |
| **Caso de uso** | Conexión rápida, backup de DX, tráfico bajo-medio | Alto ancho de banda sostenido, compliance, latencia crítica |

> **Claves examen:**
> - "Conexión **inmediata** a VPC desde on-prem" → **VPN** (DX tarda semanas)
> - "Conexión **dedicada y consistente**" → **Direct Connect**
> - "Direct Connect + cifrado" → **VPN sobre Direct Connect**
> - "Backup de Direct Connect económico" → **VPN como failover**

---

## Opciones de Conectividad VPC

| Opción | Descripción | Límites / Notas |
|--------|-------------|-----------------|
| **VPC Peering** | Conexión directa entre 2 VPCs (misma o diferente cuenta/región) | **No transitivo** — A↔B y B↔C no implica A↔C. CIDRs no deben solaparse |
| **Transit Gateway (TGW)** | Hub central que conecta múltiples VPCs, VPNs y Direct Connects | **Transitivo**. Ideal para redes complejas con muchas VPCs. Hasta 5,000 attachments |
| **VPC Endpoint (Gateway)** | Acceso privado a **S3 y DynamoDB** sin salir a internet | Gratis. Se configura en route table. Solo S3 y DynamoDB |
| **VPC Endpoint (Interface)** | Acceso privado a otros servicios AWS vía **ENI con IP privada** (PrivateLink) | Costo por hora + datos. Para la mayoría de servicios AWS y servicios de terceros |
| **AWS PrivateLink** | Exponer tu servicio a otras VPCs de forma privada vía NLB + Interface Endpoint | Unidireccional. Consumer solo necesita Interface Endpoint |
| **VPN CloudHub** | Conectar múltiples sites on-prem entre sí a través del Virtual Private Gateway | Hub-and-spoke sobre VPN. Económico |

```
VPC Peering (2 VPCs):          Transit Gateway (hub-and-spoke):

  VPC-A ←──→ VPC-B                 VPC-A ─┐
  (directo, no transitivo)         VPC-B ─┤── TGW ──┤── VPN
                                   VPC-C ─┘         └── DX

VPC Endpoints:
  EC2 (subnet privada) ──→ Gateway Endpoint ──→ S3
  EC2 (subnet privada) ──→ Interface Endpoint (ENI) ──→ Cualquier servicio AWS
```

> **Regla examen:**
> - "Conectar 2-3 VPCs" → **VPC Peering** (simple, sin costo de TGW)
> - "Conectar muchas VPCs + on-prem" → **Transit Gateway**
> - "Acceso privado a S3 sin internet" → **Gateway Endpoint** (gratis)
> - "Acceso privado a otros servicios" → **Interface Endpoint / PrivateLink**
> - "Exponer tu servicio a otras cuentas" → **PrivateLink (NLB + Interface Endpoint)**

---

## Resumen de Decisiones Rápidas - Networking

```
PREGUNTA DEL EXAMEN                                    → RESPUESTA
────────────────────────────────────────────────────────────────────
"Balanceo HTTP con routing por URL path"                → ALB
"Ultra-baja latencia / IP estática en LB"               → NLB
"Inspección de tráfico por appliance"                   → GLB (Gateway LB)
"Bloquear IP específica"                                → NACL (DENY rule)
"DR activo/pasivo con DNS"                              → Route 53 Failover
"Menor latencia para usuarios globales"                 → Route 53 Latency-based
"CDN para contenido estático/dinámico"                  → CloudFront
"IP Anycast estáticas globales"                         → Global Accelerator
"Conectar on-prem rápidamente"                          → Site-to-Site VPN
"Conexión dedicada de alto ancho de banda"              → Direct Connect
"Conectar muchas VPCs centralizadamente"                → Transit Gateway
"Acceso privado a S3 desde VPC"                         → Gateway Endpoint (gratis)
"Exponer servicio privado a otra cuenta"                → PrivateLink
```
