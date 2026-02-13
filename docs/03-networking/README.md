# Networking en AWS

## Tabla de Contenidos

- [VPC Fundamentals](#vpc-fundamentals)
- [Internet Gateway vs NAT Gateway vs NAT Instance](#internet-gateway-vs-nat-gateway-vs-nat-instance)
- [Security Groups vs NACLs](#security-groups-vs-nacls)
- [VPC Peering](#vpc-peering)
- [Transit Gateway](#transit-gateway)
- [VPC Endpoints](#vpc-endpoints)
- [VPN](#vpn)
- [AWS Direct Connect](#aws-direct-connect)
- [Elastic Load Balancing](#elastic-load-balancing)
- [Route 53](#route-53)
- [Amazon CloudFront](#amazon-cloudfront)
- [AWS Global Accelerator](#aws-global-accelerator)
- [Network Exam Tips](#network-exam-tips)

---

## VPC Fundamentals

### Qué es una VPC

Una **Virtual Private Cloud (VPC)** es una red virtual aislada lógicamente dentro de AWS donde lanzas tus recursos. Es un servicio **regional** (abarca todas las AZs de una región).

### CIDR (Classless Inter-Domain Routing)

- Al crear una VPC, defines un bloque CIDR IPv4 (obligatorio) y opcionalmente IPv6.
- Rango permitido: `/16` (65,536 IPs) hasta `/28` (16 IPs).
- Puedes añadir **CIDRs secundarios** a una VPC existente (hasta 5 por defecto).
- CIDRs comunes para redes privadas (RFC 1918):
  - `10.0.0.0/8` (10.0.0.0 - 10.255.255.255)
  - `172.16.0.0/12` (172.16.0.0 - 172.31.255.255)
  - `192.168.0.0/16` (192.168.0.0 - 192.168.255.255)

> **Importante:** El CIDR de la VPC **no debe solaparse** con otras redes a las que te vayas a conectar (on-premises, otras VPCs).

### Subnets

- Una subnet existe dentro de **una sola AZ** (no puede abarcar múltiples AZs).
- Tipos:
  - **Subnet pública**: Tiene una ruta a un Internet Gateway en su route table.
  - **Subnet privada**: No tiene ruta al Internet Gateway.
- AWS reserva **5 IPs** en cada subnet:
  - `.0` - Dirección de red.
  - `.1` - VPC router.
  - `.2` - DNS de AWS.
  - `.3` - Reservada para uso futuro.
  - `.255` - Dirección de broadcast (aunque AWS no soporta broadcast).

> **Ejemplo:** Un subnet `/24` tiene 256 IPs - 5 reservadas = **251 IPs utilizables**.

### Route Tables

- Cada subnet debe estar asociada a **exactamente una route table**.
- Una route table puede estar asociada a **múltiples subnets**.
- Existe una **Main Route Table** que se asigna por defecto a subnets sin asociación explícita.
- Regla más específica gana (longest prefix match).

**Route Table de subnet pública (ejemplo):**

| Destino | Target |
|---------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxx (Internet Gateway) |

**Route Table de subnet privada (ejemplo):**

| Destino | Target |
|---------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-xxx (NAT Gateway) |

### Default VPC

- AWS crea una VPC por defecto en cada Región con CIDR `172.31.0.0/16`.
- Incluye subnets públicas en cada AZ, Internet Gateway y configuración DNS.
- Todas las instancias lanzadas en la default VPC obtienen una IP pública automáticamente.
- No recomendada para producción. Se recomienda crear VPCs personalizadas.

---

## Internet Gateway vs NAT Gateway vs NAT Instance

| Característica | Internet Gateway (IGW) | NAT Gateway | NAT Instance |
|---------------|----------------------|-------------|--------------|
| **Propósito** | Permitir comunicación bidireccional entre VPC e Internet | Permitir que subnets privadas accedan a Internet (solo salida) | Igual que NAT Gateway (legacy) |
| **Dirección del tráfico** | Entrante y saliente | Solo saliente (outbound) | Solo saliente (outbound) |
| **Adjunto a** | VPC (1 IGW por VPC) | Subnet pública específica | Subnet pública (instancia EC2) |
| **Altamente disponible** | Sí (por diseño, redundante dentro de la Región) | Sí dentro de una AZ (crear uno por AZ para HA) | No (debes configurar failover manualmente) |
| **Escalabilidad** | Gestionado por AWS (escala automáticamente) | Hasta 100 Gbps | Depende del tipo de instancia |
| **Security Groups** | No aplica | No aplica | Sí (puedes asignar SGs) |
| **Coste** | Gratis | Coste por hora + procesamiento de datos | Coste de la instancia EC2 |
| **Mantenimiento** | Ninguno | Ninguno (gestionado) | Tú lo gestionas (parches, SO) |
| **Elastic IP** | No necesita | Asignado automáticamente | Debes asignar manualmente |
| **Bastion/Jump host** | - | No sirve como bastion | Puede servir como bastion (no recomendado) |

### Arquitectura NAT Gateway para Alta Disponibilidad

```
Region
├── AZ-a
│   ├── Public Subnet: NAT Gateway A (con Elastic IP)
│   └── Private Subnet: Route 0.0.0.0/0 -> NAT GW A
├── AZ-b
│   ├── Public Subnet: NAT Gateway B (con Elastic IP)
│   └── Private Subnet: Route 0.0.0.0/0 -> NAT GW B
└── AZ-c
    ├── Public Subnet: NAT Gateway C (con Elastic IP)
    └── Private Subnet: Route 0.0.0.0/0 -> NAT GW C
```

> **Tip para el examen:** NAT Gateway es la respuesta correcta para el 99% de preguntas sobre acceso a Internet desde subnets privadas. NAT Instance solo aparece si preguntan por la opción más barata o con Security Groups.

---

## Security Groups vs NACLs

| Característica | Security Groups | NACLs (Network ACLs) |
|---------------|----------------|---------------------|
| **Nivel** | Instancia (ENI) | Subnet |
| **Estado** | **Stateful** (el tráfico de retorno se permite automáticamente) | **Stateless** (debes definir reglas inbound Y outbound explícitamente) |
| **Tipo de reglas** | Solo reglas de **ALLOW** | Reglas de **ALLOW** y **DENY** |
| **Evaluación** | Se evalúan **todas las reglas** antes de decidir | Se evalúan **en orden numérico**; primera coincidencia gana |
| **Default** | Denegar todo inbound, permitir todo outbound | Permitir todo inbound y outbound (default NACL) |
| **Asociación** | Una instancia puede tener múltiples SGs (hasta 5) | Una subnet tiene exactamente 1 NACL |
| **Referencia a SGs** | Puede referenciar otro Security Group como origen/destino | No puede referenciar Security Groups |
| **Puertos efímeros** | No necesitas preocuparte (stateful) | Debes permitir puertos efímeros (1024-65535) en reglas outbound |

### Ejemplo de reglas

**Security Group (web server):**

| Tipo | Protocolo | Puerto | Origen |
|------|-----------|--------|--------|
| Inbound | TCP | 80 | 0.0.0.0/0 |
| Inbound | TCP | 443 | 0.0.0.0/0 |
| Inbound | TCP | 22 | sg-bastion (referencia a SG) |
| Outbound | Todo | Todo | 0.0.0.0/0 |

**NACL (subnet pública):**

| Regla # | Tipo | Protocolo | Puerto | Origen/Destino | Allow/Deny |
|---------|------|-----------|--------|---------------|------------|
| 100 | Inbound | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | Inbound | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | Inbound | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |
| * | Inbound | Todo | Todo | 0.0.0.0/0 | DENY |
| 100 | Outbound | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | Outbound | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | Outbound | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |
| * | Outbound | Todo | Todo | 0.0.0.0/0 | DENY |

> **Tip para el examen:** Si la pregunta dice "bloquear una IP específica", la respuesta es **NACL** (porque permite reglas de DENY). Los Security Groups solo permiten ALLOW.

---

## VPC Peering

- Conexión de red **privada** entre dos VPCs usando la red interna de AWS.
- Las VPCs pueden estar en **diferentes cuentas** y/o **diferentes regiones** (inter-region peering).
- Los CIDRs de las VPCs **no deben solaparse**.

### Limitaciones clave

- **No es transitivo**: Si VPC A <-> VPC B y VPC B <-> VPC C, eso **no** significa que VPC A pueda comunicarse con VPC C. Debes crear un peering directo A <-> C.
- Debes actualizar las **route tables** en ambas VPCs para dirigir el tráfico.
- Debes actualizar los **Security Groups** para permitir el tráfico desde el CIDR de la otra VPC (o referenciar el SG de la otra VPC si están en la misma región).
- No puedes crear un peering entre VPCs con CIDRs solapados.
- Máximo un peering entre dos VPCs específicas.

### Cuándo usar VPC Peering

- Conectar un **número pequeño** de VPCs.
- Comunicación directa punto a punto con baja latencia.
- No necesitas control centralizado del routing.

> **Tip para el examen:** Si la pregunta describe conectividad entre muchas VPCs (hub-and-spoke), VPC Peering no es la respuesta. Usa **Transit Gateway**.

---

## Transit Gateway

AWS Transit Gateway actúa como un **hub central** para conectar múltiples VPCs, redes on-premises y VPNs.

### Características

- **Hub-and-spoke model**: Todas las VPCs y redes se conectan al Transit Gateway.
- Soporta **peering entre Transit Gateways** de diferentes regiones (Inter-Region Peering).
- Funciona con **VPN**, **Direct Connect**, y **VPC attachments**.
- Soporta **routing tables** propias para controlar qué redes pueden comunicarse.
- Es un servicio **regional** pero soporta peering cross-region.
- Soporta **IP multicast** (único servicio de AWS que lo hace).
- Compatible con **AWS RAM (Resource Access Manager)** para compartir entre cuentas.
- Soporta **ECMP (Equal-Cost Multi-Path)** para aumentar ancho de banda de VPN.

### Cuándo usar Transit Gateway

| Escenario | VPC Peering | Transit Gateway |
|-----------|-------------|-----------------|
| Conectar 2-3 VPCs | Recomendado | Posible pero excesivo |
| Conectar 10+ VPCs | No práctico (n*(n-1)/2 peerings) | Recomendado |
| Hub-and-spoke con on-premises | No posible | Recomendado |
| Routing transitivo | No soportado | Soportado |
| IP Multicast | No soportado | Soportado |

### Transit Gateway con ECMP para VPN

- Sin ECMP: 1 conexión VPN Site-to-Site = 2 túneles = ~1.25 Gbps máximo.
- Con ECMP habilitado en Transit Gateway: puedes agregar múltiples conexiones VPN para multiplicar el throughput.
- Ejemplo: 2 conexiones VPN con ECMP = ~2.5 Gbps.

---

## VPC Endpoints

Los VPC Endpoints permiten conectar tu VPC a servicios de AWS **sin pasar por Internet**, usando la red interna de AWS.

### Tipos de VPC Endpoints

| Característica | Gateway Endpoint | Interface Endpoint (PrivateLink) |
|---------------|-----------------|--------------------------------|
| **Servicios soportados** | Solo **S3** y **DynamoDB** | La mayoría de servicios AWS + servicios de terceros |
| **Implementación** | Entrada en la route table de la subnet | ENI (Elastic Network Interface) en la subnet |
| **Coste** | **Gratis** | Coste por hora + por GB procesado |
| **Acceso** | Dentro de la VPC solamente | Desde VPC, on-premises (via VPN/DX), y VPCs conectadas |
| **Security Groups** | No (usa VPC Endpoint Policies) | Sí (SGs en la ENI) + VPC Endpoint Policies |
| **DNS** | No cambia la resolución DNS | Crea registros DNS privados (requiere DNS hostnames + DNS resolution habilitados) |
| **AZ** | Se configura por región (aplica a todas las AZs con rutas) | Se despliega por AZ (debes elegir en qué AZs) |

### Gateway Endpoint - Ejemplo con S3

1. Creas un Gateway Endpoint para S3 en tu VPC.
2. Se añade automáticamente una ruta en las route tables seleccionadas:
   - Destino: `pl-xxxxx` (prefix list de S3) -> Target: `vpce-xxxxx`.
3. El tráfico a S3 desde tu VPC ya no pasa por Internet ni por el NAT Gateway.
4. Puedes usar **VPC Endpoint Policies** para restringir qué buckets u operaciones se permiten.

### Interface Endpoint (AWS PrivateLink)

- Crea una ENI en tu subnet con una **IP privada**.
- Se resuelve via DNS privado (ej: `kinesis.us-east-1.amazonaws.com` se resuelve a la IP privada del endpoint).
- Puedes acceder desde on-premises via Site-to-Site VPN o Direct Connect.
- Para exponer tus propios servicios a otras VPCs/cuentas, usas **PrivateLink** con un **Network Load Balancer** del lado del proveedor.

### PrivateLink para exponer servicios propios

```
VPC del Consumidor                     VPC del Proveedor
┌──────────────┐                      ┌──────────────┐
│  Interface   │  AWS PrivateLink     │   Network    │
│  Endpoint    │ ──────────────────>  │   Load       │ -> Servicio
│  (ENI)       │                      │   Balancer   │
└──────────────┘                      └──────────────┘
```

> **Tip para el examen:** Si la pregunta dice "acceder a S3 sin pasar por Internet" y busca la opción más económica, usa **Gateway Endpoint** (gratis). Si es para otro servicio AWS, usa **Interface Endpoint**.

---

## VPN

### Site-to-Site VPN

Conexión cifrada (IPsec) entre tu red on-premises y tu VPC a través de Internet público.

| Componente | Descripción |
|-----------|-------------|
| **Virtual Private Gateway (VGW)** | Concentrador VPN del lado de AWS. Se adjunta a la VPC. |
| **Customer Gateway (CGW)** | Representación en AWS de tu dispositivo VPN on-premises. |
| **Customer Gateway Device** | Dispositivo físico o software en tu data center. |

- Cada conexión VPN tiene **2 túneles** para redundancia (cada túnel termina en una AZ diferente).
- Throughput máximo por túnel: ~1.25 Gbps.
- Latencia: variable (pasa por Internet público).
- Se puede establecer en minutos.

### AWS VPN CloudHub

- Permite conectar múltiples sitios on-premises entre sí a través del VGW.
- Modelo hub-and-spoke para comunicación entre sucursales.
- Tráfico entre sites pasa por la red de AWS.

### Client VPN

- Permite que usuarios individuales se conecten a AWS de forma segura usando OpenVPN.
- Los usuarios instalan un cliente VPN en su dispositivo.
- Autenticación: AD, SAML, mutual authentication (certificados).
- Tráfico cifrado desde el dispositivo del usuario hasta la VPC.

---

## AWS Direct Connect

Conexión de red **dedicada** y **privada** entre tu data center y AWS, sin pasar por Internet.

### Tipos de conexión

| Tipo | Descripción | Ancho de banda | Tiempo de provisión |
|------|-------------|----------------|-------------------|
| **Dedicated Connection** | Puerto dedicado en un router de AWS | 1 Gbps, 10 Gbps, 100 Gbps | Semanas a meses |
| **Hosted Connection** | A través de un partner de AWS | 50 Mbps hasta 10 Gbps | Semanas (depende del partner) |

### Virtual Interfaces (VIFs)

| Tipo de VIF | Propósito | Destino |
|------------|-----------|---------|
| **Private VIF** | Acceder a recursos en tu VPC | Virtual Private Gateway o Direct Connect Gateway |
| **Public VIF** | Acceder a servicios públicos de AWS (S3, DynamoDB, etc.) | Endpoints públicos de AWS |
| **Transit VIF** | Acceder a VPCs via Transit Gateway | Transit Gateway (a través de Direct Connect Gateway) |

### Direct Connect Gateway

- Permite conectar tu Direct Connect a **múltiples VPCs en diferentes regiones** (misma cuenta o cross-account).
- Es un recurso **global** (no regional).
- Se conecta al VGW de cada VPC o a un Transit Gateway.

### Cifrado en Direct Connect

- Direct Connect **no cifra** el tráfico por defecto (es una conexión dedicada, no pasa por Internet).
- Para cifrar: Establecer una **VPN Site-to-Site sobre la conexión Direct Connect** (Public VIF).
- Esto proporciona: conexión dedicada + cifrado IPsec.

### Alta disponibilidad para Direct Connect

| Nivel HA | Configuración |
|----------|---------------|
| **Básico** | 1 conexión DX a 1 ubicación |
| **HA** | 2 conexiones DX a 1 ubicación o 1 conexión DX + VPN backup |
| **Máximo HA** | 2 conexiones DX a 2 ubicaciones diferentes |

> **Tip para el examen:** Direct Connect proporciona conexión privada, consistente y de baja latencia, pero tarda semanas/meses en provisionar. Si necesitas conexión inmediata, usa VPN como puente temporal. Para máxima resiliencia, usa Direct Connect + VPN como backup.

---

## Elastic Load Balancing

### Comparación de Load Balancers

| Característica | ALB (Application) | NLB (Network) | GLB (Gateway) | CLB (Classic) |
|---------------|-------------------|---------------|---------------|---------------|
| **Capa OSI** | Capa 7 (HTTP/HTTPS) | Capa 4 (TCP/UDP/TLS) | Capa 3 (IP) | Capa 4/7 |
| **Protocolos** | HTTP, HTTPS, gRPC, WebSocket | TCP, UDP, TLS | IP (GENEVE protocol) | TCP, SSL, HTTP, HTTPS |
| **Rendimiento** | Alto | Ultra alto (millones de req/s) | Alto | Moderado |
| **IP estática** | No (usa DNS name) | Sí (**Elastic IP por AZ**) | No | No |
| **Target types** | Instance, IP, Lambda | Instance, IP, ALB | Instance, IP | Instance |
| **Health checks** | HTTP/HTTPS avanzados (path, códigos) | TCP, HTTP, HTTPS | Delegados al target group | TCP, HTTP |
| **SSL/TLS termination** | Sí | Sí (TLS termination) | No | Sí |
| **Sticky sessions** | Sí (cookie-based) | Sí (source IP) | No | Sí |
| **Cross-zone LB** | Siempre habilitado (gratis) | Deshabilitado por defecto (coste si se habilita) | Deshabilitado por defecto | Habilitado por defecto (gratis) |
| **Path-based routing** | Sí | No | No | No |
| **Host-based routing** | Sí | No | No | No |
| **WebSocket** | Sí (nativo) | Sí (por ser capa 4) | No | No |
| **Redirecciones** | Sí (HTTP->HTTPS) | No | No | No |
| **Fixed response** | Sí | No | No | No |
| **Autenticación** | Sí (Cognito, OIDC) | No | No | No |
| **Caso de uso** | Apps web, microservicios, APIs | Gaming, IoT, alta performance, IPs estáticas | Appliances virtuales (firewalls, IDS) | Legacy (no recomendado) |

### ALB - Application Load Balancer (Detalle)

- **Routing rules** basadas en:
  - Path URL (`/api/*`, `/images/*`).
  - Host header (`api.example.com`, `www.example.com`).
  - Query string y headers.
  - Source IP.
- **Target Groups**: Instancias EC2, IPs, funciones Lambda, contenedores ECS.
- **Slow Start Mode**: Incrementa gradualmente el tráfico a nuevos targets.
- El ALB añade el header `X-Forwarded-For` con la IP original del cliente.

### NLB - Network Load Balancer (Detalle)

- Proporciona **Elastic IP** (IP estática) por cada AZ donde esté desplegado.
- Ideal cuando necesitas whitelisting por IP.
- Puede ser target de un ALB (para combinar IP estática + routing avanzado).
- Latencia extremadamente baja (~100ms vs ~400ms de ALB).
- **Preserve source IP**: La IP del cliente se ve directamente en el target (a diferencia del ALB que la pone en X-Forwarded-For).

### GLB - Gateway Load Balancer (Detalle)

- Funciona en **capa 3 (red)** usando el protocolo **GENEVE** (puerto 6081).
- Diseñado para desplegar, escalar y gestionar **appliances virtuales de terceros**: firewalls, IDS/IPS, deep packet inspection.
- El tráfico pasa primero por el GLB, luego a los appliances, y vuelve al GLB antes de llegar al destino.
- **Transparente** para las aplicaciones (no modifica paquetes).

### Sticky Sessions (Session Affinity)

| Tipo | Load Balancer | Mecanismo |
|------|--------------|-----------|
| **Duration-based** | ALB, CLB | Cookie generada por ELB (`AWSALB` / `AWSELB`) |
| **Application-based** | ALB | Cookie de tu aplicación (nombre personalizado) |
| **Source IP** | NLB | Hash de la IP de origen |

### Cross-Zone Load Balancing

- **Habilitado**: El tráfico se distribuye uniformemente entre **todos los targets registrados** en todas las AZs.
- **Deshabilitado**: El tráfico se distribuye uniformemente entre las AZs, sin importar el número de targets en cada una.

### Connection Draining / Deregistration Delay

- Tiempo que el ELB espera para completar las solicitudes en curso antes de desregistrar un target no saludable.
- Configurable de 0 a 3600 segundos (default: 300 segundos).
- Configurar a 0 si las solicitudes son muy cortas.

---

## Route 53

Amazon Route 53 es el servicio DNS gestionado de AWS. Es un servicio **global** (no regional).

### Record Types

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **A** | Mapea un nombre a una dirección IPv4 | `www.example.com` -> `1.2.3.4` |
| **AAAA** | Mapea un nombre a una dirección IPv6 | `www.example.com` -> `2001:db8::1` |
| **CNAME** | Mapea un nombre a otro nombre DNS | `blog.example.com` -> `www.example.com` |
| **Alias** | Mapea un nombre a un recurso de AWS (extensión de AWS, no estándar DNS) | `example.com` -> `d1234.cloudfront.net` |
| **MX** | Servidores de correo | `example.com` -> `mail.example.com` |
| **NS** | Name servers de la hosted zone | `example.com` -> `ns-xxx.awsdns-xxx.com` |
| **TXT** | Texto arbitrario (verificación de dominio, SPF) | `example.com` -> `"v=spf1 include:..."` |
| **SRV** | Servicio específico (puerto + protocolo) | `_sip._tcp.example.com` -> `10 60 5060 sipserver.example.com` |
| **PTR** | Reverse DNS (IP a nombre) | `4.3.2.1.in-addr.arpa` -> `www.example.com` |

### CNAME vs Alias

| Característica | CNAME | Alias |
|---------------|-------|-------|
| **Zone apex** | No (no puede apuntar `example.com` directamente) | Sí (puede apuntar `example.com`) |
| **Targets** | Cualquier hostname DNS | Solo recursos AWS (ELB, CloudFront, S3 website, API GW, etc.) |
| **Coste de queries** | Normal (se cobra) | **Gratis** cuando apunta a recursos AWS |
| **Health checks** | Sí (del target) | Sí (configurable) |
| **TTL** | Configurable | Gestionado automáticamente por Route 53 |

> **Tip para el examen:** Si necesitas apuntar el dominio raíz (`example.com`) a un ELB o CloudFront, **debes** usar un registro **Alias** (CNAME no permite zone apex).

### Routing Policies

| Política | Descripción | Caso de uso | Health Checks |
|----------|-------------|-------------|---------------|
| **Simple** | Devuelve uno o más valores. Si hay múltiples, el cliente elige aleatoriamente | Routing básico | No |
| **Weighted** | Distribuye el tráfico según pesos asignados (0-255) | A/B testing, migración gradual | Sí |
| **Latency-based** | Enruta al recurso con menor latencia desde el usuario | Aplicaciones multi-región | Sí |
| **Failover** | Activo-pasivo. Enruta al secundario si el primario falla | DR (Disaster Recovery) | Sí (obligatorio en primario) |
| **Geolocation** | Enruta según la ubicación geográfica del usuario (continente, país, estado) | Contenido localizado, compliance | Sí |
| **Geoproximity** | Enruta según distancia geográfica al recurso. Permite ajustar con **bias** para expandir/contraer áreas | Control fino de distribución geográfica | Sí |
| **Multi-Value Answer** | Devuelve hasta 8 records saludables aleatoriamente | Client-side load balancing simple | Sí |
| **IP-based** | Enruta según el rango IP del cliente (CIDR) | Optimización por ISP o empresa | Sí |

### Health Checks de Route 53

| Tipo | Descripción |
|------|-------------|
| **Endpoint** | Monitoriza un endpoint (IP o hostname). Soporta HTTP, HTTPS, TCP. |
| **Calculated** | Combina el estado de múltiples health checks con lógica AND/OR. |
| **CloudWatch Alarm** | Se basa en el estado de un CloudWatch Alarm (útil para recursos privados). |

- Los health checkers están en **Internet público**, por lo que no pueden acceder a endpoints privados directamente.
- Para recursos privados, usa **CloudWatch Alarm** + health check basado en el alarm.

---

## Amazon CloudFront

Amazon CloudFront es la CDN (Content Delivery Network) de AWS, distribuida globalmente con más de 400 Edge Locations.

### Conceptos clave

| Concepto | Descripción |
|----------|-------------|
| **Origin** | El origen del contenido: S3 bucket, ALB, EC2, HTTP server personalizado |
| **Distribution** | La configuración de CloudFront (dominio `dxxxx.cloudfront.net`) |
| **Behavior** | Reglas que definen cómo CloudFront maneja las solicitudes según path pattern |
| **Edge Location** | Donde se cachea el contenido |
| **Regional Edge Cache** | Capa intermedia entre Edge Location y Origin (para contenido menos popular) |

### Origins soportados

| Origin | Notas |
|--------|-------|
| **S3 Bucket** | Puede usar OAC/OAI para restringir acceso solo via CloudFront |
| **S3 Website Endpoint** | Para S3 static website hosting (origin personalizado) |
| **ALB** | Debe ser público; SG del ALB debe permitir IPs de CloudFront |
| **EC2** | Debe ser público (o accesible via IP pública) |
| **Custom HTTP** | Cualquier servidor web accesible por HTTP/HTTPS |
| **MediaStore / MediaPackage** | Para streaming de video |

### Origin Access Control (OAC) vs Origin Access Identity (OAI)

| Característica | OAI (Legacy) | OAC (Recomendado) |
|---------------|-------------|-------------------|
| **Soporte SSE-KMS** | No | Sí |
| **HTTP methods** | Solo GET | Todos (GET, PUT, POST, DELETE) |
| **Regiones** | Todas | Todas |
| **S3 bucket policy** | Referencia al OAI | Referencia al servicio CloudFront |
| **Estado** | Legacy, aún funciona | Recomendado para nuevos deployments |

### Cache Policies y Origin Request Policies

- **Cache Policy**: Define qué se incluye en la cache key (headers, query strings, cookies).
  - **TTL**: Min TTL, Max TTL, Default TTL.
  - CloudFront primero respeta los headers `Cache-Control` del origin.
- **Origin Request Policy**: Define qué headers/cookies/query strings se envían al origin (sin afectar la cache key).

### CloudFront Functions vs Lambda@Edge

| Característica | CloudFront Functions | Lambda@Edge |
|---------------|---------------------|-------------|
| **Runtime** | JavaScript (ligero) | Node.js, Python |
| **Escala** | Millones de req/s | Miles de req/s |
| **Triggers** | Viewer Request / Viewer Response | Viewer Request/Response + Origin Request/Response |
| **Duración máx.** | < 1 ms | 5s (viewer) / 30s (origin) |
| **Memoria** | 2 MB | 128 MB - 10 GB |
| **Acceso red** | No | Sí |
| **Caso de uso** | Manipulación headers, URL rewrites/redirects, cache key normalization | Cambios complejos, acceso a servicios externos, modificación de body |

### Signed URLs vs Signed Cookies

| Característica | Signed URL | Signed Cookie |
|---------------|-----------|---------------|
| **Acceso** | Un archivo específico por URL | Múltiples archivos |
| **Uso** | Descarga de un archivo individual | Acceso a conjunto de contenido (streaming, área privada) |
| **Implementación** | URL con parámetros de firma | Cookies en el navegador |

> Se usan para restringir acceso a contenido privado. Requieren un **trusted key group** (recomendado) o **CloudFront key pair** (legacy, solo root).

### Geo-Restriction

- **Allowlist**: Solo permitir acceso desde países específicos.
- **Blocklist**: Bloquear acceso desde países específicos.
- Basado en una base de datos de geolocalización de IPs de terceros.

---

## AWS Global Accelerator

AWS Global Accelerator mejora la disponibilidad y el rendimiento del tráfico global dirigiendo el tráfico a endpoints óptimos a través de la red global de AWS.

### Cómo funciona

1. Se te asignan **2 IPs anycast estáticas** (o puedes traer las tuyas - BYOIP).
2. Los usuarios se conectan a la Edge Location más cercana.
3. Desde la Edge Location, el tráfico viaja por la **red privada de AWS** (AWS backbone) hasta el endpoint.
4. Endpoints soportados: ALB, NLB, EC2, Elastic IP.

### CloudFront vs Global Accelerator

| Característica | CloudFront | Global Accelerator |
|---------------|------------|-------------------|
| **Tipo** | CDN (Content Delivery Network) | Acelerador de red |
| **Capa** | Capa 7 (HTTP/HTTPS) | Capa 4 (TCP/UDP) |
| **Cacheo** | Sí (cachea contenido en Edge Locations) | No (no cachea, solo enruta) |
| **IPs estáticas** | No (DNS name) | Sí (2 IPs anycast globales) |
| **Ideal para** | Contenido estático y dinámico HTTP/HTTPS | TCP/UDP no-HTTP, gaming, IoT, VoIP |
| **SSL termination** | En Edge Location | En el endpoint |
| **Failover** | Origin failover | Endpoint failover instantáneo (<30s) |
| **Protocolos** | HTTP, HTTPS, WebSocket | TCP, UDP |

> **Tip para el examen:** Si la pregunta menciona "IP estática global" o "tráfico TCP/UDP no-HTTP", usa **Global Accelerator**. Si menciona "cacheo de contenido" o "CDN", usa **CloudFront**.

---

## Network Exam Tips

### VPC

- El CIDR de la VPC **no puede cambiarse** después de crearse (pero puedes añadir CIDRs secundarios).
- AWS reserva **5 IPs** por subnet.
- Las subnets son de una sola AZ. Las VPCs son regionales.
- Default VPC: `172.31.0.0/16` con subnets públicas por defecto.

### Gateways y NAT

- **1 IGW por VPC**. Sin IGW, no hay acceso a Internet.
- NAT Gateway está en una subnet pública y permite salida a Internet desde subnets privadas.
- Para HA de NAT, crear **un NAT Gateway por AZ**.
- NAT Gateway no soporta Security Groups (NAT Instance sí).

### Security

- **Security Groups = stateful, solo ALLOW**. NACLs = stateless, ALLOW + DENY.
- Para bloquear una IP: usa **NACL** con regla DENY.
- NACLs se evalúan en orden numérico (primera coincidencia gana).

### Conectividad

- **VPC Peering**: No transitivo. Para pocos VPCs.
- **Transit Gateway**: Hub-and-spoke. Para muchos VPCs y/o redes on-premises. Soporta multicast.
- **VPC Endpoint Gateway**: S3 y DynamoDB. Gratis.
- **VPC Endpoint Interface**: Otros servicios. Con coste. Usa PrivateLink.
- **PrivateLink** con NLB para exponer servicios propios a otras VPCs.

### VPN y Direct Connect

- **Site-to-Site VPN**: Cifrado IPsec sobre Internet. Rápido de configurar. ~1.25 Gbps por túnel.
- **Direct Connect**: Conexión privada dedicada. Tarda semanas/meses. Hasta 100 Gbps. No cifrado por defecto.
- **DX + VPN**: Cifrado sobre Direct Connect (mejor de ambos mundos).
- Direct Connect Gateway para conectar a múltiples VPCs en diferentes regiones.

### Load Balancing

- **ALB**: HTTP/HTTPS, path routing, host routing, Lambda targets. No IP estática.
- **NLB**: TCP/UDP, ultra rápido, IP estática (Elastic IP). Preserva source IP.
- **GLB**: Appliances virtuales (firewalls). Protocolo GENEVE.
- **CLB**: Legacy. No usar en nuevos despliegues.
- Cross-zone: Habilitado por defecto en ALB (gratis). Deshabilitado por defecto en NLB (con coste).

### DNS (Route 53)

- Es un servicio **global**.
- **Alias** para zone apex. CNAME **no** puede ser zone apex.
- **Failover** routing para DR. Necesita health check en primario.
- **Latency-based** para multi-región.
- **Geolocation** para compliance y contenido localizado.
- Health checks no pueden acceder a recursos privados directamente (usar CloudWatch Alarm).

### CDN y Aceleración

- **CloudFront** cachea contenido. Usa OAC para S3 (no OAI). Certificado ACM debe estar en us-east-1.
- **Global Accelerator**: 2 IPs anycast estáticas. No cachea. Para TCP/UDP.
- CloudFront Functions para operaciones simples y rápidas. Lambda@Edge para lógica compleja.
- Signed URLs para archivos individuales. Signed Cookies para múltiples archivos.
