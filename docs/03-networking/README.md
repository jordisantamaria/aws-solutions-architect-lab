# Networking in AWS

## Table of Contents

- [VPC Fundamentals](#vpc-fundamentals)
- [Internet Gateway vs NAT Gateway vs NAT Instance](#internet-gateway-vs-nat-gateway-vs-nat-instance)
- [IPv6 Networking and Egress-Only Internet Gateway](#ipv6-networking-and-egress-only-internet-gateway)
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

### What is a VPC

A **Virtual Private Cloud (VPC)** is a logically isolated virtual network within AWS where you launch your resources. It is a **regional** service (spans all AZs in a region).

### CIDR (Classless Inter-Domain Routing)

- When creating a VPC, you define an IPv4 CIDR block (required) and optionally IPv6.
- Allowed range: `/16` (65,536 IPs) to `/28` (16 IPs).
- You can add **secondary CIDRs** to an existing VPC (up to 5 by default).
- Common CIDR ranges for private networks (RFC 1918):
  - `10.0.0.0/8` (10.0.0.0 - 10.255.255.255)
  - `172.16.0.0/12` (172.16.0.0 - 172.31.255.255)
  - `192.168.0.0/16` (192.168.0.0 - 192.168.255.255)

> **Important:** The VPC CIDR **must not overlap** with other networks you will connect to (on-premises, other VPCs).

### Subnets

- A subnet exists within **a single AZ** (it cannot span multiple AZs).
- Types:
  - **Public subnet**: Has a route to an Internet Gateway in its route table.
  - **Private subnet**: Has no route to the Internet Gateway.
- AWS reserves **5 IPs** in each subnet:
  - `.0` - Network address.
  - `.1` - VPC router.
  - `.2` - AWS DNS.
  - `.3` - Reserved for future use.
  - `.255` - Broadcast address (although AWS does not support broadcast).

> **Example:** A `/24` subnet has 256 IPs - 5 reserved = **251 usable IPs**.

### Route Tables

- Each subnet must be associated with **exactly one route table**.
- A route table can be associated with **multiple subnets**.
- There is a **Main Route Table** that is assigned by default to subnets without explicit association.
- Most specific route wins (longest prefix match).

**Public subnet Route Table (example):**

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxx (Internet Gateway) |

**Private subnet Route Table (example):**

| Destination | Target |
|-------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-xxx (NAT Gateway) |

### Subnet Planning: tiers x AZs formula

When designing a VPC, the number of subnets is calculated as:

```
Number of subnets = Number of tiers × Number of AZs
```

**Typical example of 3 tiers in 2 AZs = 6 subnets:**

```
                    AZ-a              AZ-b
                ┌──────────┐     ┌──────────┐
Public:         │ pub-1a   │     │ pub-1b   │    ← ALB, NAT GW, Bastion
                ├──────────┤     ├──────────┤
Private (App):  │ priv-1a  │     │ priv-1b  │    ← EC2, ECS, Lambda
                ├──────────┤     ├──────────┤
Private (Data): │ data-1a  │     │ data-1b  │    ← RDS, ElastiCache
                └──────────┘     └──────────┘
```

**With 3 AZs = 9 subnets.** Each subnet has its own route table and NACL.

> **Exam tip:** If the question says "3-tier architecture across 2 AZs", think 6 subnets. If it says "3 AZs for high availability", it will be 9 subnets.

### Default VPC

- AWS creates a default VPC in each Region with CIDR `172.31.0.0/16`.
- Includes public subnets in each AZ, Internet Gateway, and DNS configuration.
- All instances launched in the default VPC automatically get a public IP.
- Not recommended for production. Creating custom VPCs is recommended.

---

## Internet Gateway vs NAT Gateway vs NAT Instance

| Feature | Internet Gateway (IGW) | NAT Gateway | NAT Instance |
|---------|----------------------|-------------|--------------|
| **Purpose** | Allow bidirectional communication between VPC and Internet | Allow private subnets to access the Internet (outbound only, **IPv4 only**) | Same as NAT Gateway (legacy) |
| **Traffic direction** | Inbound and outbound | Outbound only | Outbound only |
| **Attached to** | VPC (1 IGW per VPC) | Specific public subnet | Public subnet (EC2 instance) |
| **Highly available** | Yes (by design, redundant within the Region) | Yes within one AZ (create one per AZ for HA) | No (you must configure failover manually) |
| **Scalability** | Managed by AWS (scales automatically) | Up to 100 Gbps | Depends on instance type |
| **Security Groups** | Not applicable | Not applicable | Yes (you can assign SGs) |
| **Cost** | Free | Hourly cost + data processing | EC2 instance cost |
| **Maintenance** | None | None (managed) | You manage it (patches, OS) |
| **Elastic IP** | Not needed | Automatically assigned | Must assign manually |
| **Bastion/Jump host** | - | Cannot serve as bastion | Can serve as bastion (not recommended) |

### NAT Gateway Architecture for High Availability

```
Region
├── AZ-a
│   ├── Public Subnet: NAT Gateway A (with Elastic IP)
│   └── Private Subnet: Route 0.0.0.0/0 -> NAT GW A
├── AZ-b
│   ├── Public Subnet: NAT Gateway B (with Elastic IP)
│   └── Private Subnet: Route 0.0.0.0/0 -> NAT GW B
└── AZ-c
    ├── Public Subnet: NAT Gateway C (with Elastic IP)
    └── Private Subnet: Route 0.0.0.0/0 -> NAT GW C
```

### Cost: NAT Gateway vs NAT Instance

| Scenario | NAT Gateway | NAT Instance (t3.micro) |
|----------|------------|------------------------|
| 1 AZ (no HA) | ~$32/month + $0.045/GB processed | ~$7.50/month (no per-GB cost) |
| 3 AZs (HA) | ~$97/month + data | ~$22.50/month |
| 3 AZs + 500 GB data/month | ~$120/month | ~$22.50/month |

- NAT Gateway is significantly more expensive but **zero maintenance** (no OS to patch, auto-scales to 100 Gbps, AWS manages availability within the AZ).
- NAT Instance is cheaper but **you manage everything** (patches, monitoring, failover, manual scaling).
- In **production**, the cost of engineer hours managing NAT Instances exceeds the Gateway cost.
- In **dev/test or side projects**, NAT Instance with t3.nano (~$3.74/month) is reasonable to save money.
- With NAT Instance you can use **a single NAT for all AZs** (accepting the single point of failure risk). With NAT Gateway you need one per AZ for HA.
- **Regional NAT Gateway** (new): You create a single regional NAT Gateway that automatically expands to AZs where there is traffic. The per-AZ cost is the same ($0.045/h/AZ), but if your workload stops using an AZ, it stops charging for it automatically.

### Savings Tip: VPC Gateway Endpoint for S3/DynamoDB

If instances in private subnets frequently access S3 or DynamoDB, that traffic goes through the NAT Gateway and you pay $0.045/GB in data processing. **This is unnecessary.** A VPC Gateway Endpoint routes traffic directly to S3/DynamoDB through AWS's internal network, **at no cost**.

```
WITHOUT Endpoint:  EC2 (private) → NAT Gateway ($0.045/GB) → Internet → S3
WITH Endpoint:     EC2 (private) → VPC Gateway Endpoint ($0)  → S3 (direct)
```

Gateway VPC Endpoints are free and support S3 and DynamoDB. If your private subnet moves 1 TB/month to S3, you save $45/month in NAT data processing alone.

> **Exam tip:** NAT Gateway is the correct answer for 99% of questions about Internet access from private subnets. NAT Instance only appears if they ask for "the cheapest option" or "security groups on the NAT". If they ask "reduce NAT Gateway costs when accessing S3" -> **VPC Gateway Endpoint**. If they ask about **IPv6 outbound-only** -> **Egress-Only Internet Gateway** (NAT Gateway does not support IPv6).

---

## IPv6 Networking and Egress-Only Internet Gateway

### IPv6 in VPC

- When creating a VPC, you can assign an IPv6 `/56` CIDR block provided by Amazon (or bring your own via BYOIP).
- Each subnet can receive an IPv6 `/64` block.
- Unlike IPv4, **all IPv6 addresses are public** (the concept of RFC 1918 private ranges does not exist).
- An instance with IPv6 in a public subnet with IGW has bidirectional communication with the Internet via IPv6.

### Egress-Only Internet Gateway

It is the equivalent of NAT Gateway but **exclusively for IPv6**. It allows instances to initiate outbound connections to the Internet via IPv6, but **blocks inbound connections initiated from the Internet**.

| Feature | NAT Gateway | Egress-Only Internet Gateway |
|---------|-------------|------------------------------|
| **Protocol** | **IPv4 only** | **IPv6 only** |
| **Purpose** | Outbound IPv4 from private subnets | Outbound IPv6 from private subnets |
| **Blocks inbound** | Yes (only allows return traffic) | Yes (only allows return traffic) |
| **Is stateful** | Yes | Yes |
| **Attached to** | Specific public subnet | VPC (like the IGW) |
| **Cost** | ~$0.045/h + $0.045/GB processed | **Free** (you only pay for data transferred) |

### Route Table Configuration

```
Private subnet Route Table (dual-stack IPv4 + IPv6):

| Destination     | Target                              |
|-----------------|-------------------------------------|
| 10.0.0.0/16     | local                               |
| 0.0.0.0/0       | nat-xxx (NAT Gateway - IPv4)        |
| ::/0            | eigw-xxx (Egress-Only IGW - IPv6)   |
```

### Why NAT Gateway Does Not Work for IPv6

NAT (Network Address Translation) translates private IPs to a public IP. But in IPv6 **there are no private IPs** -- all are public and globally unique. There is no translation to be done. That's why AWS created a different mechanism: the Egress-Only Internet Gateway, which simply filters traffic direction (allows outbound, blocks inbound) without performing NAT.

### Traffic Inspection: Network Firewall vs Traffic Mirroring vs Firewall Manager

If an exam question combines IPv6 outbound with traffic inspection, these are the relevant services:

| Service | Purpose | When to use |
|---------|---------|-------------|
| **AWS Network Firewall** | Managed firewall with deep inspection (IDS/IPS, Layer 3-7) | "Inspect traffic", "filter traffic", "IDS/IPS" |
| **VPC Traffic Mirroring** | Copy of network traffic for analysis (does not block, only observes) | "Capture traffic for analysis", "packet capture" |
| **AWS Firewall Manager** | Centralized management of firewall rules across multiple accounts/VPCs | "Manage firewall rules across the organization" |

> **Exam tip:**
> - "IPv6 + outbound only + block inbound" -> **Egress-Only Internet Gateway** (not NAT Gateway).
> - "Traffic inspection + filtering" -> **AWS Network Firewall** (not Traffic Mirroring, which only copies; not Firewall Manager, which only manages rules).
> - "Copy traffic for offline analysis" -> **Traffic Mirroring**.

---

## Security Groups vs NACLs

| Feature | Security Groups | NACLs (Network ACLs) |
|---------|----------------|---------------------|
| **Level** | Instance (ENI) | Subnet |
| **State** | **Stateful** (return traffic is automatically allowed) | **Stateless** (you must define inbound AND outbound rules explicitly) |
| **Rule types** | Only **ALLOW** rules | **ALLOW** and **DENY** rules |
| **Evaluation** | **All rules** are evaluated before deciding | Evaluated **in numerical order**; first match wins |
| **Default** | Deny all inbound, allow all outbound | Allow all inbound and outbound (default NACL) |
| **Association** | An instance can have multiple SGs (up to 5) | A subnet has exactly 1 NACL |
| **SG references** | Can reference another Security Group as source/destination | Cannot reference Security Groups |
| **Ephemeral ports** | No need to worry (stateful) | Must allow ephemeral ports (1024-65535) in outbound rules |

### Rule Examples

**Security Group (web server):**

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| Inbound | TCP | 80 | 0.0.0.0/0 |
| Inbound | TCP | 443 | 0.0.0.0/0 |
| Inbound | TCP | 22 | sg-bastion (SG reference) |
| Outbound | All | All | 0.0.0.0/0 |

**NACL (public subnet):**

| Rule # | Type | Protocol | Port | Source/Dest | Allow/Deny |
|--------|------|----------|------|-------------|------------|
| 100 | Inbound | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | Inbound | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | Inbound | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |
| * | Inbound | All | All | 0.0.0.0/0 | DENY |
| 100 | Outbound | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | Outbound | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | Outbound | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW |
| * | Outbound | All | All | 0.0.0.0/0 | DENY |

> **Exam tip:** If the question says "block a specific IP", the answer is **NACL** (because it allows DENY rules). Security Groups only allow ALLOW.

---

## VPC Peering

- **Private** network connection between two VPCs using AWS's internal network.
- VPCs can be in **different accounts** and/or **different regions** (inter-region peering).
- VPC CIDRs **must not overlap**.

### Key Limitations

- **Not transitive**: If VPC A <-> VPC B and VPC B <-> VPC C, that does **not** mean VPC A can communicate with VPC C. You must create a direct peering A <-> C.
- You must update **route tables** in both VPCs to direct traffic.
- You must update **Security Groups** to allow traffic from the other VPC's CIDR (or reference the other VPC's SG if they are in the same region).
- You cannot create peering between VPCs with overlapping CIDRs.
- Maximum one peering between two specific VPCs.

### When to Use VPC Peering

- Connecting a **small number** of VPCs.
- Direct point-to-point communication with low latency.
- No need for centralized routing control.

> **Exam tip:** If the question describes connectivity between many VPCs (hub-and-spoke), VPC Peering is not the answer. Use **Transit Gateway**.

---

## Transit Gateway

AWS Transit Gateway acts as a **central hub** for connecting multiple VPCs, on-premises networks, and VPNs.

### Features

- **Hub-and-spoke model**: All VPCs and networks connect to the Transit Gateway.
- Supports **peering between Transit Gateways** in different regions (Inter-Region Peering).
- Works with **VPN**, **Direct Connect**, and **VPC attachments**.
- Supports its own **routing tables** to control which networks can communicate.
- It is a **regional** service but supports cross-region peering.
- Supports **IP multicast** (the only AWS service that does).
- Compatible with **AWS RAM (Resource Access Manager)** for sharing between accounts.
- Supports **ECMP (Equal-Cost Multi-Path)** to increase VPN bandwidth.

### When to Use Transit Gateway

| Scenario | VPC Peering | Transit Gateway |
|----------|-------------|-----------------|
| Connect 2-3 VPCs | Recommended | Possible but overkill |
| Connect 10+ VPCs | Not practical (n*(n-1)/2 peerings) | Recommended |
| Hub-and-spoke with on-premises | Not possible | Recommended |
| Transitive routing | Not supported | Supported |
| IP Multicast | Not supported | Supported |

### Transit Gateway with ECMP for VPN

- Without ECMP: 1 Site-to-Site VPN connection = 2 tunnels = ~1.25 Gbps maximum.
- With ECMP enabled on Transit Gateway: you can add multiple VPN connections to multiply throughput.
- Example: 2 VPN connections with ECMP = ~2.5 Gbps.

---

## VPC Endpoints

VPC Endpoints allow you to connect your VPC to AWS services **without going through the Internet**, using AWS's internal network.

### Types of VPC Endpoints

| Feature | Gateway Endpoint | Interface Endpoint (PrivateLink) |
|---------|-----------------|--------------------------------|
| **Supported services** | Only **S3** and **DynamoDB** | Most AWS services + third-party services |
| **Implementation** | Entry in the subnet's route table | ENI (Elastic Network Interface) in the subnet |
| **Cost** | **Free** | Hourly cost + per GB processed |
| **Access** | Within the VPC only | From VPC, on-premises (via VPN/DX), and connected VPCs |
| **Security Groups** | No (uses VPC Endpoint Policies) | Yes (SGs on the ENI) + VPC Endpoint Policies |
| **DNS** | Does not change DNS resolution | Creates private DNS records (requires DNS hostnames + DNS resolution enabled) |
| **AZ** | Configured per region (applies to all AZs with routes) | Deployed per AZ (you must choose which AZs) |

### Gateway Endpoint - Example with S3

1. Create a Gateway Endpoint for S3 in your VPC.
2. A route is automatically added to the selected route tables:
   - Destination: `pl-xxxxx` (S3 prefix list) -> Target: `vpce-xxxxx`.
3. Traffic to S3 from your VPC no longer goes through the Internet or NAT Gateway.
4. You can use **VPC Endpoint Policies** to restrict which buckets or operations are allowed.

### Interface Endpoint (AWS PrivateLink)

- Creates an ENI in your subnet with a **private IP**.
- Resolved via private DNS (e.g., `kinesis.us-east-1.amazonaws.com` resolves to the endpoint's private IP).
- You can access from on-premises via Site-to-Site VPN or Direct Connect.
- To expose your own services to other VPCs/accounts, use **PrivateLink** with a **Network Load Balancer** on the provider side.

### PrivateLink for Exposing Your Own Services

```
Consumer VPC                           Provider VPC
┌──────────────┐                      ┌──────────────┐
│  Interface   │  AWS PrivateLink     │   Network    │
│  Endpoint    │ ──────────────────>  │   Load       │ -> Service
│  (ENI)       │                      │   Balancer   │
└──────────────┘                      └──────────────┘
```

> **Exam tip:** If the question says "access S3 without going through the Internet" and looks for the most cost-effective option, use **Gateway Endpoint** (free). If it's for another AWS service, use **Interface Endpoint**.

---

## VPN

### Site-to-Site VPN

Encrypted connection (IPsec) between your on-premises network and your VPC through the public Internet.

| Component | Description |
|-----------|-------------|
| **Virtual Private Gateway (VGW)** | VPN concentrator on the AWS side. Attached to the VPC. |
| **Customer Gateway (CGW)** | AWS representation of your on-premises VPN device. |
| **Customer Gateway Device** | Physical or software device in your data center. |

- Each VPN connection has **2 tunnels** for redundancy (each tunnel terminates in a different AZ).
- Maximum throughput per tunnel: ~1.25 Gbps.
- Latency: variable (goes through public Internet).
- Can be established in minutes.

### AWS VPN CloudHub

- Allows connecting multiple on-premises sites to each other through the VGW.
- Hub-and-spoke model for communication between branch offices.
- Traffic between sites goes through the AWS network.

### Client VPN

- Allows individual users to connect to AWS securely using OpenVPN.
- Users install a VPN client on their device.
- Authentication: AD, SAML, mutual authentication (certificates).
- Encrypted traffic from the user's device to the VPC.

---

## AWS Direct Connect

**Dedicated** and **private** network connection between your data center and AWS, without going through the Internet.

### Connection Types

| Type | Description | Bandwidth | Provisioning Time |
|------|-------------|-----------|-------------------|
| **Dedicated Connection** | Dedicated port on an AWS router | 1 Gbps, 10 Gbps, 100 Gbps | Weeks to months |
| **Hosted Connection** | Through an AWS partner | 50 Mbps to 10 Gbps | Weeks (depends on partner) |

### Virtual Interfaces (VIFs)

| VIF Type | Purpose | Destination |
|----------|---------|-------------|
| **Private VIF** | Access resources in your VPC | Virtual Private Gateway or Direct Connect Gateway |
| **Public VIF** | Access public AWS services (S3, DynamoDB, etc.) | AWS public endpoints |
| **Transit VIF** | Access VPCs via Transit Gateway | Transit Gateway (through Direct Connect Gateway) |

### Direct Connect Gateway

- Allows connecting your Direct Connect to **multiple VPCs in different regions** (same account or cross-account).
- It is a **global** resource (not regional).
- Connects to each VPC's VGW or to a Transit Gateway.

### Encryption on Direct Connect

- Direct Connect **does not encrypt** traffic by default (it's a dedicated connection, doesn't go through the Internet).
- To encrypt: Establish a **Site-to-Site VPN over the Direct Connect connection** (Public VIF).
- This provides: dedicated connection + IPsec encryption.

### High Availability for Direct Connect

| HA Level | Configuration |
|----------|---------------|
| **Basic** | 1 DX connection to 1 location |
| **HA** | 2 DX connections to 1 location or 1 DX connection + VPN backup |
| **Maximum HA** | 2 DX connections to 2 different locations |

> **Exam tip:** Direct Connect provides a private, consistent, low-latency connection, but takes weeks/months to provision. If you need an immediate connection, use VPN as a temporary bridge. For maximum resilience, use Direct Connect + VPN as backup.

---

## Elastic Load Balancing

### Load Balancer Comparison

| Feature | ALB (Application) | NLB (Network) | GLB (Gateway) | CLB (Classic) |
|---------|-------------------|---------------|---------------|---------------|
| **OSI Layer** | Layer 7 (HTTP/HTTPS) | Layer 4 (TCP/UDP/TLS) | Layer 3 (IP) | Layer 4/7 |
| **Protocols** | HTTP, HTTPS, gRPC, WebSocket | TCP, UDP, TLS | IP (GENEVE protocol) | TCP, SSL, HTTP, HTTPS |
| **Performance** | High | Ultra high (millions of req/s) | High | Moderate |
| **Static IP** | No (uses DNS name) | Yes (**Elastic IP per AZ**) | No | No |
| **Target types** | Instance, IP, Lambda | Instance, IP, ALB | Instance, IP | Instance |
| **Health checks** | Advanced HTTP/HTTPS (path, codes) | TCP, HTTP, HTTPS | Delegated to target group | TCP, HTTP |
| **SSL/TLS termination** | Yes | Yes (TLS termination) | No | Yes |
| **Sticky sessions** | Yes (cookie-based) | Yes (source IP) | No | Yes |
| **Cross-zone LB** | Always enabled (free) | Disabled by default (cost if enabled) | Disabled by default | Enabled by default (free) |
| **Path-based routing** | Yes | No | No | No |
| **Host-based routing** | Yes | No | No | No |
| **WebSocket** | Yes (native) | Yes (being Layer 4) | No | No |
| **Redirects** | Yes (HTTP->HTTPS) | No | No | No |
| **Fixed response** | Yes | No | No | No |
| **Authentication** | Yes (Cognito, OIDC) | No | No | No |
| **Use case** | Web apps, microservices, APIs | Gaming, IoT, high performance, static IPs | Virtual appliances (firewalls, IDS) | Legacy (not recommended) |

### ALB - Application Load Balancer (Detail)

- **Routing rules** based on:
  - URL path (`/api/*`, `/images/*`).
  - Host header (`api.example.com`, `www.example.com`).
  - Query string and headers.
  - Source IP.
- **Target Groups**: EC2 instances, IPs, Lambda functions, ECS containers.
- **Slow Start Mode**: Gradually increases traffic to new targets.
- ALB adds the `X-Forwarded-For` header with the original client IP.
- **ALB is regional**: Cannot have targets in other regions. For multi-region distribution, use Route 53 or Global Accelerator.

#### ALB Weighted Target Groups

ALB supports assigning **weights** to Target Groups to distribute traffic proportionally:

```
ALB Listener Rule:
  ├── Target Group A (on-premises IPs via Direct Connect): weight 90
  └── Target Group B (EC2 in AWS): weight 10
```

- Allows **gradual migration** (blue/green, canary) by moving weight from one TG to another.
- **Target type IP**: Allows registering private IPs **outside AWS** (on-premises servers accessible via Direct Connect or VPN).
- Use case: Gradual migration from on-premises to AWS. Send 90% to on-prem, 10% to AWS. Progressively adjust weights.

> **Exam tip:** If the question mentions "gradual migration from on-premises to AWS" + "percentage-based traffic distribution" -> **ALB with Weighted Target Groups** using target type IP for on-premises servers (via Direct Connect).

### NLB - Network Load Balancer (Detail)

- Provides **Elastic IP** (static IP) for each AZ where it is deployed.
- Ideal when you need IP whitelisting.
- Can be a target of an ALB (to combine static IP + advanced routing).
- Extremely low latency (~100ms vs ~400ms for ALB).
- **Preserve source IP**: The client IP is seen directly on the target (unlike ALB which puts it in X-Forwarded-For).

#### NLB and HTTP Health Checks

Although NLB operates at **Layer 4**, it supports health checks on **HTTP and HTTPS** (not just TCP):

| Health Check Protocol | Available on NLB |
|---|---|
| TCP | Yes |
| HTTP | **Yes** |
| HTTPS | **Yes** |

> **Exam trap:** If a question says "NLB with application layer health checks" and offers as an option "replace NLB with ALB" vs "configure HTTP health checks on NLB", the correct answer is **configure HTTP health checks on the existing NLB** (least operational overhead). NLB does support HTTP health checks, even though it operates at Layer 4.

### GLB - Gateway Load Balancer (Detail)

- Operates at **Layer 3 (network)** using the **GENEVE** protocol (port 6081).
- Designed to deploy, scale, and manage **third-party virtual appliances**: firewalls, IDS/IPS, deep packet inspection.
- Traffic first goes through the GLB, then to the appliances, and returns to the GLB before reaching the destination.
- **Transparent** to applications (does not modify packets).

### Sticky Sessions (Session Affinity)

| Type | Load Balancer | Mechanism |
|------|--------------|-----------|
| **Duration-based** | ALB, CLB | Cookie generated by ELB (`AWSALB` / `AWSELB`) |
| **Application-based** | ALB | Your application's cookie (custom name) |
| **Source IP** | NLB | Source IP hash |

### Cross-Zone Load Balancing

- **Enabled**: Traffic is distributed evenly across **all registered targets** in all AZs.
- **Disabled**: Traffic is distributed evenly between AZs, regardless of the number of targets in each.

### Connection Draining / Deregistration Delay

- Time the ELB waits to complete in-flight requests before deregistering an unhealthy target.
- Configurable from 0 to 3600 seconds (default: 300 seconds).
- Set to 0 if requests are very short.

---

## Route 53

Amazon Route 53 is AWS's managed DNS service. It is a **global** service (not regional).

### Record Types

| Type | Description | Example |
|------|-------------|---------|
| **A** | Maps a name to an IPv4 address | `www.example.com` -> `1.2.3.4` |
| **AAAA** | Maps a name to an IPv6 address | `www.example.com` -> `2001:db8::1` |
| **CNAME** | Maps a name to another DNS name | `blog.example.com` -> `www.example.com` |
| **Alias** | Maps a name to an AWS resource (AWS extension, not standard DNS) | `example.com` -> `d1234.cloudfront.net` |
| **MX** | Mail servers | `example.com` -> `mail.example.com` |
| **NS** | Name servers for the hosted zone | `example.com` -> `ns-xxx.awsdns-xxx.com` |
| **TXT** | Arbitrary text (domain verification, SPF) | `example.com` -> `"v=spf1 include:..."` |
| **SRV** | Specific service (port + protocol) | `_sip._tcp.example.com` -> `10 60 5060 sipserver.example.com` |
| **PTR** | Reverse DNS (IP to name) | `4.3.2.1.in-addr.arpa` -> `www.example.com` |

### CNAME vs Alias

| Feature | CNAME | Alias |
|---------|-------|-------|
| **Zone apex** | No (cannot point `example.com` directly) | Yes (can point `example.com`) |
| **Targets** | Any DNS hostname | Only AWS resources (ELB, CloudFront, S3 website, API GW, etc.) |
| **Query cost** | Normal (charged) | **Free** when pointing to AWS resources |
| **Health checks** | Yes (of the target) | Yes (configurable) |
| **TTL** | Configurable | Automatically managed by Route 53 |

> **Exam tip:** If you need to point the root domain (`example.com`) to an ELB or CloudFront, you **must** use an **Alias** record (CNAME does not allow zone apex).

### Routing Policies

| Policy | Description | Use Case | Health Checks |
|--------|-------------|----------|---------------|
| **Simple** | Returns one or more values. If multiple, the client chooses randomly | Basic routing | No |
| **Weighted** | Distributes traffic according to assigned weights (0-255) | A/B testing, gradual migration | Yes |
| **Latency-based** | Routes to the resource with lowest latency from the user | Multi-region applications | Yes |
| **Failover** | Active-passive. Routes to secondary if primary fails | DR (Disaster Recovery) | Yes (mandatory on primary) |
| **Geolocation** | Routes based on the user's geographic location (continent, country, state) | Localized content, compliance | Yes |
| **Geoproximity** | Routes based on geographic distance to the resource. Allows adjusting with **bias** to expand/contract areas | Fine-grained geographic distribution control | Yes |
| **Multi-Value Answer** | Returns up to 8 healthy records randomly | Simple client-side load balancing | Yes |
| **IP-based** | Routes based on the client's IP range (CIDR) | Optimization by ISP or company | Yes |

### Route 53 Health Checks

| Type | Description |
|------|-------------|
| **Endpoint** | Monitors an endpoint (IP or hostname). Supports HTTP, HTTPS, TCP. |
| **Calculated** | Combines the status of multiple health checks with AND/OR logic. |
| **CloudWatch Alarm** | Based on the state of a CloudWatch Alarm (useful for private resources). |

- Health checkers are on the **public Internet**, so they cannot access private endpoints directly.
- For private resources, use **CloudWatch Alarm** + alarm-based health check.

---

## Amazon CloudFront

Amazon CloudFront is AWS's CDN (Content Delivery Network), globally distributed with more than 400 Edge Locations.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Origin** | The source of content: S3 bucket, ALB, EC2, custom HTTP server |
| **Distribution** | The CloudFront configuration (domain `dxxxx.cloudfront.net`) |
| **Behavior** | Rules that define how CloudFront handles requests based on path pattern |
| **Edge Location** | Where content is cached |
| **Regional Edge Cache** | Intermediate layer between Edge Location and Origin (for less popular content) |

### Supported Origins

| Origin | Notes |
|--------|-------|
| **S3 Bucket** | Can use OAC/OAI to restrict access only via CloudFront |
| **S3 Website Endpoint** | For S3 static website hosting (custom origin) |
| **ALB** | Must be public; ALB SG must allow CloudFront IPs |
| **EC2** | Must be public (or accessible via public IP) |
| **Custom HTTP** | Any web server accessible by HTTP/HTTPS |
| **MediaStore / MediaPackage** | For video streaming |

### Origin Access Control (OAC) vs Origin Access Identity (OAI)

| Feature | OAI (Legacy) | OAC (Recommended) |
|---------|-------------|-------------------|
| **SSE-KMS support** | No | Yes |
| **HTTP methods** | GET only | All (GET, PUT, POST, DELETE) |
| **Regions** | All | All |
| **S3 bucket policy** | References the OAI | References the CloudFront service |
| **Status** | Legacy, still works | Recommended for new deployments |

### Cache Policies and Origin Request Policies

- **Cache Policy**: Defines what is included in the cache key (headers, query strings, cookies).
  - **TTL**: Min TTL, Max TTL, Default TTL.
  - CloudFront first respects the origin's `Cache-Control` headers.
- **Origin Request Policy**: Defines which headers/cookies/query strings are sent to the origin (without affecting the cache key).

### Origin Groups (Origin Failover)

An Origin Group contains a **primary** and a **secondary** origin. If the primary returns errors (500, 502, 503, 504), CloudFront automatically retries the request with the secondary.

```
Without Origin Group:
  CloudFront ──► Origin (ALB) ──► fails with 504 ──► user sees 504 error

With Origin Group:
  CloudFront ──► Primary (ALB eu-west-1) ──► fails with 504
                     │
                     ▼ (automatic, transparent)
                 Secondary (ALB us-east-1) ──► responds OK ──► user doesn't notice
```

**Use cases:**
- **Origin HA**: primary in one region, secondary in another.
- **S3 failover**: primary = main S3 bucket, secondary = S3 bucket replica in another region.
- **Fallback to static content**: primary = ALB (dynamic), secondary = S3 (maintenance page).

You don't always need an origin group -- only when you need origin high availability or you're seeing frequent 5xx errors.

### CloudFront Functions vs Lambda@Edge

| Feature | CloudFront Functions | Lambda@Edge |
|---------|---------------------|-------------|
| **Runtime** | JavaScript (lightweight) | Node.js, Python |
| **Scale** | Millions of req/s | Thousands of req/s |
| **Triggers** | Viewer Request / Viewer Response | Viewer Request/Response + Origin Request/Response |
| **Max duration** | < 1 ms | 5s (viewer) / 30s (origin) |
| **Memory** | 2 MB | 128 MB - 10 GB |
| **Network access** | No | Yes |
| **Use case** | Header manipulation, URL rewrites/redirects, cache key normalization | Complex changes, access to external services, body modification |

### Lambda@Edge for Authentication

Lambda@Edge can act as **authentication middleware at the edge**, validating tokens (JWT) before the request reaches your origin. It does not replace your app's login -- it only verifies tokens on subsequent requests.

```
1. Login (first time):
   User ──► CloudFront ──► Origin (your app) ──► validates user/password ──► returns JWT
   (this is still your app, as always)

2. Subsequent requests (protected routes):
   User sends JWT ──► CloudFront Edge ──► Lambda@Edge verifies JWT
                                                 │
                                            Valid JWT?
                                            ├── Yes → passes to origin
                                            └── No → returns 302 redirect to /login
                                                     (the origin never knows)
```

**Configured per Behavior** (path pattern). Only protected routes execute Lambda@Edge:

```
CloudFront Distribution (Behaviors)
├── /login*        → Passes directly to origin (no Lambda@Edge)
├── /api/auth/*    → Passes directly to origin (no Lambda@Edge)
├── /static/*      → Serves from S3 (no Lambda@Edge)
└── /api/*         → Lambda@Edge validates JWT before passing to origin
```

**Benefits:**
- Requests with invalid tokens are rejected at the edge, **without loading the origin**.
- JWT validation is fast (verify signature, no DB query needed).
- The user authenticates against the nearest edge (~5ms) instead of the distant origin (~200ms).

> **Exam tip:** If the question says "reduce authentication latency" or "run auth logic at the edge" -> **Lambda@Edge**. If it says "simple header manipulation or URL rewrites" -> **CloudFront Functions** (faster and cheaper).

### Signed URLs vs Signed Cookies

| Feature | Signed URL | Signed Cookie |
|---------|-----------|---------------|
| **Access** | One specific file per URL | Multiple files |
| **Use** | Download of an individual file | Access to a content set (streaming, private area) |
| **Implementation** | URL with signature parameters | Cookies in the browser |

> Used to restrict access to private content. Require a **trusted key group** (recommended) or **CloudFront key pair** (legacy, root only).

### Geo-Restriction

- **Allowlist**: Only allow access from specific countries.
- **Blocklist**: Block access from specific countries.
- Based on a third-party IP geolocation database.

---

## AWS Global Accelerator

AWS Global Accelerator improves the availability and performance of global traffic by directing traffic to optimal endpoints through AWS's global network.

### How It Works

1. You are assigned **2 static anycast IPs** (or you can bring your own - BYOIP).
2. Users connect to the nearest Edge Location.
3. From the Edge Location, traffic travels through the **AWS private network** (AWS backbone) to the endpoint.
4. Supported endpoints: ALB, NLB, EC2, Elastic IP.

### CloudFront vs Global Accelerator

| Feature | CloudFront | Global Accelerator |
|---------|------------|-------------------|
| **Type** | CDN (Content Delivery Network) | Network accelerator |
| **Layer** | Layer 7 (HTTP/HTTPS) | Layer 4 (TCP/UDP) |
| **Caching** | Yes (caches content at Edge Locations) | No (does not cache, only routes) |
| **Static IPs** | No (DNS name) | Yes (2 global anycast IPs) |
| **Ideal for** | Static and dynamic HTTP/HTTPS content | Non-HTTP TCP/UDP, gaming, IoT, VoIP |
| **SSL termination** | At Edge Location | At the endpoint |
| **Failover** | Origin failover | Instant endpoint failover (<30s) |
| **Protocols** | HTTP, HTTPS, WebSocket | TCP, UDP |

> **Exam tip:** If the question mentions "global static IP" or "non-HTTP TCP/UDP traffic", use **Global Accelerator**. If it mentions "content caching" or "CDN", use **CloudFront**.

---

## Network Exam Tips

### VPC

- The VPC CIDR **cannot be changed** after creation (but you can add secondary CIDRs).
- AWS reserves **5 IPs** per subnet.
- Subnets are single-AZ. VPCs are regional.
- Default VPC: `172.31.0.0/16` with public subnets by default.

### Gateways and NAT

- **1 IGW per VPC**. Without IGW, there's no Internet access.
- NAT Gateway is in a public subnet and allows outbound Internet access from private subnets. **IPv4 only.**
- **Egress-Only Internet Gateway** is the NAT Gateway equivalent for **IPv6** (outbound-only, blocks inbound).
- For NAT HA, create **one NAT Gateway per AZ**.
- NAT Gateway does not support Security Groups (NAT Instance does).

### Security

- **Security Groups = stateful, ALLOW only**. NACLs = stateless, ALLOW + DENY.
- To block an IP: use **NACL** with a DENY rule.
- NACLs are evaluated in numerical order (first match wins).

### Connectivity

- **VPC Peering**: Not transitive. For few VPCs.
- **Transit Gateway**: Hub-and-spoke. For many VPCs and/or on-premises networks. Supports multicast.
- **VPC Endpoint Gateway**: S3 and DynamoDB. Free.
- **VPC Endpoint Interface**: Other services. Has cost. Uses PrivateLink.
- **PrivateLink** with NLB to expose your own services to other VPCs.

### VPN and Direct Connect

- **Site-to-Site VPN**: IPsec encryption over Internet. Quick to set up. ~1.25 Gbps per tunnel.
- **Direct Connect**: Dedicated private connection. Takes weeks/months. Up to 100 Gbps. Not encrypted by default.
- **DX + VPN**: Encryption over Direct Connect (best of both worlds).
- Direct Connect Gateway to connect to multiple VPCs in different regions.

### Load Balancing

- **ALB**: HTTP/HTTPS, path routing, host routing, Lambda targets. No static IP.
- **NLB**: TCP/UDP, ultra fast, static IP (Elastic IP). Preserves source IP.
- **GLB**: Virtual appliances (firewalls). GENEVE protocol.
- **CLB**: Legacy. Do not use for new deployments.
- Cross-zone: Enabled by default on ALB (free). Disabled by default on NLB (with cost).

### DNS (Route 53)

- It is a **global** service.
- **Alias** for zone apex. CNAME **cannot** be zone apex.
- **Failover** routing for DR. Requires health check on primary.
- **Latency-based** for multi-region.
- **Geolocation** for compliance and localized content.
- Health checks cannot access private resources directly (use CloudWatch Alarm).

### CDN and Acceleration

- **CloudFront** caches content. Use OAC for S3 (not OAI). ACM certificate must be in us-east-1.
- **Global Accelerator**: 2 static anycast IPs. Does not cache. For TCP/UDP.
- CloudFront Functions for simple, fast operations. Lambda@Edge for complex logic.
- Signed URLs for individual files. Signed Cookies for multiple files.
- **Origin Group**: primary + secondary origin. If the primary returns 5xx, CloudFront retries with the secondary automatically. For origin HA.
- **"504 errors in CloudFront"** -> Origin Group (automatic failover) or review origin timeouts.
- **"Reduce authentication latency"** -> Lambda@Edge (validates JWT at the edge without going to the origin).
