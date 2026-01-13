# Cloud DNS Operations

## AWS Route 53

### Record Types & Routing Policies
| Policy | Description | Use Case |
|--------|-------------|----------|
| Simple | Single value, no health checks | Basic DNS |
| Weighted | Distribute traffic by weight | Blue/green deployment |
| Latency | Route to lowest latency region | Global apps |
| Failover | Primary/secondary with health check | HA |
| Geolocation | Route by client location | Compliance, localization |
| Geoproximity | Route by geographic distance | Traffic shifting |
| Multivalue | Multiple healthy values (up to 8) | Simple load balancing |

### Route 53 CLI Examples
```bash
# List hosted zones
aws route53 list-hosted-zones

# Get records in a zone
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890

# Create/update records (JSON changeset)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890 \
  --change-batch file://changes.json
```

### Change Batch JSON
```json
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "www.example.com",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "192.0.2.1"}]
    }
  }]
}
```

### Alias Records (Route 53 Specific)
```json
{
  "Name": "example.com",
  "Type": "A",
  "AliasTarget": {
    "HostedZoneId": "Z2FDTNDATAQYW2",
    "DNSName": "d111111abcdef8.cloudfront.net",
    "EvaluateTargetHealth": true
  }
}
```

### Route 53 Resolver (Hybrid DNS)
```bash
# Create outbound endpoint (VPC to on-prem)
aws route53resolver create-resolver-endpoint \
  --creator-request-id $(date +%s) \
  --direction OUTBOUND \
  --ip-addresses SubnetId=subnet-123,Ip=10.0.1.10

# Create forwarding rule
aws route53resolver create-resolver-rule \
  --domain-name corp.internal \
  --rule-type FORWARD \
  --resolver-endpoint-id rslvr-out-123 \
  --target-ips Ip=10.1.1.53,Port=53
```

## Cloudflare DNS

### API Examples
```bash
# List zones
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CF_TOKEN"

# Create DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "www",
    "content": "192.0.2.1",
    "ttl": 300,
    "proxied": true
  }'

# Update record
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"content": "192.0.2.2"}'
```

### Cloudflare-Specific Features
| Feature | Description |
|---------|-------------|
| Proxied records | Orange cloud - traffic through CF (DDoS, CDN) |
| DNS-only | Grey cloud - just DNS, no proxy |
| CNAME flattening | Automatic at apex (returns A/AAAA) |
| Secondary DNS | AXFR from your primary |
| DNSSEC | One-click enable |

### Terraform Example
```hcl
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = "192.0.2.1"
  type    = "A"
  ttl     = 300
  proxied = true
}
```

## Google Cloud DNS

### gcloud CLI
```bash
# Create managed zone
gcloud dns managed-zones create example-zone \
  --dns-name="example.com." \
  --description="Production zone"

# Start a transaction
gcloud dns record-sets transaction start --zone=example-zone

# Add record
gcloud dns record-sets transaction add "192.0.2.1" \
  --name="www.example.com." \
  --ttl=300 \
  --type=A \
  --zone=example-zone

# Execute transaction
gcloud dns record-sets transaction execute --zone=example-zone

# List records
gcloud dns record-sets list --zone=example-zone
```

### Private Zones (GCP)
```bash
# Create private zone
gcloud dns managed-zones create private-zone \
  --dns-name="internal.example.com." \
  --visibility=private \
  --networks=default

# Enable inbound forwarding (on-prem to GCP)
gcloud dns policies create inbound-policy \
  --networks=default \
  --enable-inbound-forwarding
```

## Azure DNS

### Azure CLI
```bash
# Create DNS zone
az network dns zone create \
  --resource-group myResourceGroup \
  --name example.com

# Add A record
az network dns record-set a add-record \
  --resource-group myResourceGroup \
  --zone-name example.com \
  --record-set-name www \
  --ipv4-address 192.0.2.1

# Create alias record to Azure resource
az network dns record-set a create \
  --resource-group myResourceGroup \
  --zone-name example.com \
  --name apex \
  --target-resource /subscriptions/.../publicIPAddresses/myPublicIP
```

### Private DNS Zones (Azure)
```bash
# Create private zone
az network private-dns zone create \
  --resource-group myResourceGroup \
  --name private.example.com

# Link to VNet
az network private-dns link vnet create \
  --resource-group myResourceGroup \
  --zone-name private.example.com \
  --name myVNetLink \
  --virtual-network myVNet \
  --registration-enabled true
```

## Multi-Cloud DNS Patterns

### Active-Active with Health Checks
```
                    ┌──────────────┐
                    │   Primary    │
User → DNS ─────────┤   (Route53)  │──→ AWS Region
       (GSLB)       │              │
                    ├──────────────┤
                    │   Secondary  │
                    │   (Cloud DNS)│──→ GCP Region
                    └──────────────┘
```

### NS Delegation Pattern
```zone
; Parent zone at registrar points to multiple clouds
example.com.  IN NS ns1.route53.example.com.
example.com.  IN NS ns2.route53.example.com.
example.com.  IN NS ns1.cloudflare.example.com.
example.com.  IN NS ns2.cloudflare.example.com.
```
