# Networking - Quick Cheat Sheet

## VPC Components

| Component | Description |
|-----------|-------------|
| **VPC** | Isolated virtual network in AWS. You define the CIDR range (e.g.: 10.0.0.0/16). Max 5 VPCs per region (expandable) |
| **Subnet** | Segment of the VPC within **a single AZ**. Public (with route to IGW) or private |
| **Internet Gateway (IGW)** | Enables communication between the VPC and the internet. One per VPC. Horizontally scaled |
| **NAT Gateway** | Allows instances in **private** subnets to access the internet (outbound). Managed, high availability in one AZ |
| **NAT Instance** | Same as NAT GW but using an EC2 instance (cheaper, less scalable, more management) |
| **Route Table** | Defines traffic routes. Each subnet is associated with a route table |
| **Elastic IP** | Static public IPv4. Associated with instances or NAT Gateways |
| **CIDR Block** | IP range of the VPC. Primary + up to 4 secondary. Minimum /28, maximum /16 |
| **ENI** | Elastic Network Interface — virtual NIC. Can be moved between instances in the same AZ |
| **Flow Logs** | Captures IP traffic (accept/reject) at VPC, subnet, or ENI level. Sent to CloudWatch Logs or S3 |

> **Exam key:**
> - **NAT Gateway** for high availability → deploy one **per AZ**.
> - **IGW** is required for a subnet to be public (+ route table with 0.0.0.0/0 → IGW route + public IP).

---

## Security Groups vs NACLs

| Feature | Security Group | Network ACL (NACL) |
|---------|----------------|-------------------|
| **Level** | **Instance** (ENI) | **Subnet** |
| **Type** | **Stateful** | **Stateless** |
| **Rules** | Only **ALLOW** | ALLOW **and DENY** |
| **Evaluation** | All rules evaluated before deciding | Rules evaluated **in numerical order** (first match wins) |
| **Return traffic** | **Automatic** (stateful) | Must be **explicitly** allowed (stateless) |
| **Default (VPC)** | Deny all inbound, Allow all outbound | Allow all inbound and outbound |
| **Default (custom)** | Deny all inbound, Allow all outbound | **Deny all** inbound and outbound |
| **Association** | Assigned to instances | Assigned to **subnets** |
| **Quantity** | Up to 5 SGs per ENI | 1 NACL per subnet |

```
Internet → NACL (subnet-level) → Security Group (instance-level) → EC2 Instance
                                                                         │
EC2 Instance → Security Group (auto-allow return) → NACL (needs outbound rule) → Internet
```

> **Exam rule:**
> - "Block a specific IP" → **NACL** (can do explicit DENY)
> - "Allow traffic between instances" → **Security Group** (reference another SG)
> - "Stateful" = Security Group. "Stateless" = NACL.

---

## Elastic Load Balancer (ELB) Types

| Feature | ALB | NLB | GLB |
|---------|-----|-----|-----|
| **Full name** | Application Load Balancer | Network Load Balancer | Gateway Load Balancer |
| **OSI layer** | **Layer 7** (HTTP/HTTPS) | **Layer 4** (TCP/UDP/TLS) | **Layer 3** (IP) |
| **Protocol** | HTTP, HTTPS, gRPC, WebSocket | TCP, UDP, TLS | IP (GENEVE encapsulation) |
| **Performance** | Good | **Ultra-high** (millions of req/s) | High |
| **Latency** | ~400 ms | **~100 us** (ultra-low) | Variable |
| **Static IP** | No (DNS name) | **Yes** (Elastic IP per AZ) | No |
| **SSL termination** | Yes | Yes | No |
| **Advanced routing** | **Yes** (path, host, header, query string) | No | No |
| **Sticky sessions** | Yes | No (flow hash) | No |
| **Targets** | Instances, IPs, Lambda, containers | Instances, IPs, ALB | Instances, IPs (appliances) |
| **Use case** | Web apps, microservices, content routing | Gaming, IoT, ultra-low latency, static IP | Firewalls, IDS/IPS, deep packet inspection |

> **Exam tricks:**
> - "URL path-based routing" → **ALB**
> - "Static IP" or "ultra-low latency" → **NLB**
> - "Inspect traffic with third-party appliance" → **GLB**
> - "Need both static IP and L7 routing" → **NLB in front of ALB**

---

## Route 53 - Routing Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| **Simple** | One record, one or more values. Route 53 returns all, client picks randomly | Simple website with no special requirements |
| **Weighted** | Distributes traffic by **assigned weights** (0-255) | A/B testing, gradual deployment (10% new, 90% old) |
| **Latency-based** | Routes to the resource with **lowest latency** from the user | Multi-region apps, optimize user experience |
| **Failover** | Active/passive with **health checks**. If primary fails, redirects to secondary | Active-passive DR, static S3 backup sites |
| **Geolocation** | Routing based on the user's **geographic location** (continent, country) | Localized content, legal restrictions by country |
| **Geoproximity** | Routing based on geographic distance + **bias** to expand/reduce zone | Granular control of traffic distribution by region |
| **Multi-value answer** | Returns multiple IPs **with health checks** for each one | Simple client-side balancing with health checking |
| **IP-based** | Routing based on the **client's IP range** (CIDR blocks) | Specific ISPs, corporate office IP ranges |

> **Exam key:**
> - "Lowest latency for global users" → **Latency-based**
> - "Active/passive DR" → **Failover**
> - "Different content by country" → **Geolocation**
> - "Gradual deployment / canary" → **Weighted**

---

## CloudFront vs Global Accelerator

| Feature | CloudFront | Global Accelerator |
|---------|------------|-------------------|
| **Type** | CDN (Content Delivery Network) | Network layer accelerator |
| **Content** | **Caches content** at edge locations | **Does not cache** — network-level proxy |
| **Protocol** | HTTP/HTTPS | TCP/UDP (any protocol) |
| **IPs** | DNS domain (d123.cloudfront.net) | **2 static Anycast IPs** |
| **Edge Locations** | 400+ global PoPs | Same edge network |
| **Use case** | Static/dynamic web content, streaming, APIs | Non-HTTP TCP/UDP apps, gaming, IoT, global static IP |
| **DDoS** | AWS Shield Standard included | AWS Shield Standard included |
| **Failover** | Origin failover groups | Endpoint health checks + instant failover |

> **Exam rule:**
> - "Accelerate web content / API / static" → **CloudFront**
> - "Global static IPs" or "non-HTTP protocol" → **Global Accelerator**
> - "Both" if they need static IP + HTTP content → **Global Accelerator in front of ALB**

---

## VPN vs Direct Connect

| Feature | Site-to-Site VPN | Direct Connect (DX) |
|---------|------------------|---------------------|
| **Connection** | Internet (encrypted with IPSec) | Dedicated private fiber |
| **Setup time** | **Minutes** | **Weeks to months** |
| **Bandwidth** | Limited by internet (~1.25 Gbps per tunnel) | **1 Gbps, 10 Gbps, 100 Gbps** (dedicated) |
| **Latency** | Variable (internet) | **Consistent and low** |
| **Cost** | Lower (per hour + data) | Higher (monthly port + data) |
| **Encryption** | **Yes** (native IPSec) | **Not** native (add VPN over DX for encryption) |
| **Redundancy** | Two tunnels by default | Second DX or VPN backup |
| **Use case** | Quick connection, DX backup, low-medium traffic | High sustained bandwidth, compliance, critical latency |

> **Exam keys:**
> - "**Immediate** connection to VPC from on-prem" → **VPN** (DX takes weeks)
> - "**Dedicated and consistent** connection" → **Direct Connect**
> - "Direct Connect + encryption" → **VPN over Direct Connect**
> - "Economical Direct Connect backup" → **VPN as failover**

---

## VPC Connectivity Options

| Option | Description | Limits / Notes |
|--------|-------------|----------------|
| **VPC Peering** | Direct connection between 2 VPCs (same or different account/region) | **Not transitive** — A↔B and B↔C does not imply A↔C. CIDRs must not overlap |
| **Transit Gateway (TGW)** | Central hub connecting multiple VPCs, VPNs, and Direct Connects | **Transitive**. Ideal for complex networks with many VPCs. Up to 5,000 attachments |
| **VPC Endpoint (Gateway)** | Private access to **S3 and DynamoDB** without going to the internet | Free. Configured in route table. S3 and DynamoDB only |
| **VPC Endpoint (Interface)** | Private access to other AWS services via **ENI with private IP** (PrivateLink) | Hourly + data cost. For most AWS services and third-party services |
| **AWS PrivateLink** | Expose your service to other VPCs privately via NLB + Interface Endpoint | Unidirectional. Consumer only needs Interface Endpoint |
| **VPN CloudHub** | Connect multiple on-prem sites through the Virtual Private Gateway | Hub-and-spoke over VPN. Economical |

```
VPC Peering (2 VPCs):          Transit Gateway (hub-and-spoke):

  VPC-A ←──→ VPC-B                 VPC-A ─┐
  (direct, not transitive)        VPC-B ─┤── TGW ──┤── VPN
                                   VPC-C ─┘         └── DX

VPC Endpoints:
  EC2 (private subnet) ──→ Gateway Endpoint ──→ S3
  EC2 (private subnet) ──→ Interface Endpoint (ENI) ──→ Any AWS service
```

> **Exam rule:**
> - "Connect 2-3 VPCs" → **VPC Peering** (simple, no TGW cost)
> - "Connect many VPCs + on-prem" → **Transit Gateway**
> - "Private access to S3 without internet" → **Gateway Endpoint** (free)
> - "Private access to other services" → **Interface Endpoint / PrivateLink**
> - "Expose your service to other accounts" → **PrivateLink (NLB + Interface Endpoint)**

---

## Quick Decision Summary - Networking

```
EXAM QUESTION                                        → ANSWER
────────────────────────────────────────────────────────────────────
"HTTP load balancing with URL path routing"           → ALB
"Ultra-low latency / static IP on LB"                 → NLB
"Traffic inspection by appliance"                     → GLB (Gateway LB)
"Block specific IP"                                   → NACL (DENY rule)
"Active/passive DR with DNS"                          → Route 53 Failover
"Lowest latency for global users"                     → Route 53 Latency-based
"CDN for static/dynamic content"                      → CloudFront
"Global static Anycast IPs"                           → Global Accelerator
"Connect on-prem quickly"                             → Site-to-Site VPN
"Dedicated high-bandwidth connection"                 → Direct Connect
"Centrally connect many VPCs"                         → Transit Gateway
"Private access to S3 from VPC"                       → Gateway Endpoint (free)
"Expose private service to another account"           → PrivateLink
```
