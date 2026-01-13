# DNS Security Deep Dive

## Response Policy Zones (RPZ)

### Purpose
- DNS-based filtering/blocking at resolver level
- Block malware domains, implement parental controls
- Override responses for specific domains

### RPZ Triggers (Query Matching)
| Trigger | Format | Description |
|---------|--------|-------------|
| QNAME | domain.rpz.zone | Match query name |
| IP | prefix.rpz-ip.zone | Match response IP |
| NSDNAME | ns.rpz-nsdname.zone | Match NS name |
| NSIP | prefix.rpz-nsip.zone | Match NS IP |
| CLIENT-IP | prefix.rpz-client-ip.zone | Match client IP |

### RPZ Actions (Policy)
| Action | Record | Effect |
|--------|--------|--------|
| NXDOMAIN | CNAME . | Return NXDOMAIN |
| NODATA | CNAME *. | Return empty answer |
| PASSTHRU | CNAME rpz-passthru. | Allow query |
| DROP | CNAME rpz-drop. | Drop silently |
| Local Data | A/AAAA/CNAME | Return specified data |

### RPZ Zone Example
```zone
$TTL 300
$ORIGIN rpz.example.com.
@   IN  SOA localhost. root.localhost. (
        2024011301 1800 900 604800 86400 )
    IN  NS  localhost.

; Block malware domain (NXDOMAIN)
malware.example.evil. CNAME .

; Redirect phishing to warning page
phishing.site.evil.   CNAME warning.example.com.

; Block by response IP (sinkhole)
32.2.0.192.rpz-ip     CNAME .

; Allow specific domain despite other rules
allowed.example.com.  CNAME rpz-passthru.

; Wildcard block entire TLD
*.evil.               CNAME .
```

### BIND RPZ Configuration
```
options {
    response-policy {
        zone "rpz.malware.local" policy nxdomain;
        zone "rpz.custom.local";
    };
};

zone "rpz.malware.local" {
    type primary;
    file "/etc/bind/rpz/malware.db";
    allow-query { none; };
};
```

### Unbound RPZ (via rpz module)
```yaml
rpz:
    name: "rpz.example.com."
    zonefile: "/etc/unbound/rpz.zone"
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz-block"
```

## DNS Rebinding Attacks

### Attack Flow
```
1. Victim visits attacker.com
2. DNS: attacker.com → 1.2.3.4 (attacker's server)
3. JavaScript loads in victim's browser
4. DNS TTL expires
5. DNS: attacker.com → 192.168.1.1 (victim's internal)
6. Same-origin allows JS to access internal resource
```

### Mitigations

**Resolver-Side (DNS Pinning)**
```yaml
# Unbound: block private IPs in responses
server:
    private-address: 10.0.0.0/8
    private-address: 172.16.0.0/12
    private-address: 192.168.0.0/16
    private-address: fd00::/8
    private-domain: "local"
    private-domain: "internal"
```

**Application-Side**
- Validate Host header against expected values
- Implement CORS properly
- Use authentication for internal services
- Network segmentation

**Browser-Side**
- DNS pinning (browsers cache DNS longer than TTL)
- Private Network Access spec (formerly CORS-RFC1918)

## Anycast DNS

### Concept
- Same IP advertised from multiple locations via BGP
- Queries routed to nearest/best path instance
- Automatic failover if one site goes down

### Deployment Architecture
```
                     ┌─────────────┐
           ┌────────→│  DC1 (US)   │
           │         │ 192.0.2.53  │
           │         └─────────────┘
           │
Users ─────┼─────────┐
(BGP)      │         │ ┌─────────────┐
           │         └→│  DC2 (EU)   │
           │           │ 192.0.2.53  │
           │           └─────────────┘
           │
           │         ┌─────────────┐
           └────────→│  DC3 (APAC) │
                     │ 192.0.2.53  │
                     └─────────────┘
```

### BGP Configuration (Bird Example)
```
protocol bgp upstream {
    local as 65001;
    neighbor 10.0.0.1 as 65000;

    ipv4 {
        export filter {
            if net = 192.0.2.53/32 then accept;
            reject;
        };
    };
}

protocol static anycast_dns {
    ipv4;
    route 192.0.2.53/32 blackhole;
}
```

### Anycast Considerations
| Aspect | Consideration |
|--------|---------------|
| Catchment | BGP determines which users reach which site |
| Failover | BGP withdrawal propagation time (seconds to minutes) |
| Consistency | All sites must serve identical zone data |
| Debugging | Use NSID/CHAOS to identify responding site |
| TCP/DNSSEC | Works but state not shared between sites |

## DNS Flag Days

### Historical Flag Days
| Date | Issue | Resolution |
|------|-------|------------|
| 2019-02-01 | EDNS workarounds | Resolvers stop retrying without EDNS |
| 2020-10-01 | IP fragmentation | Responses truncate at 1232 bytes |

### Testing EDNS Compliance
```bash
# Check EDNS support
dig +norec +dnssec @ns.example.com example.com

# Test with specific buffer size (1232 = current recommendation)
dig +bufsize=1232 example.com

# Test TCP fallback
dig +tcp example.com DNSKEY

# Use ISC's checker
dig @ednscomp.isc.org test.example.com TXT
```

### EDNS Compliance Checklist
- [ ] Server responds to EDNS queries with EDNS
- [ ] Server responds with TC=1 when response > buffer size
- [ ] Server handles unknown EDNS options gracefully
- [ ] Server supports TCP for truncated responses
- [ ] Server doesn't require DO bit for EDNS

## DNS Cache Poisoning Defenses

### Attack Surface
| Vector | Defense |
|--------|---------|
| Predictable TXID | Randomize 16-bit transaction ID |
| Predictable port | Randomize source port |
| Birthday attack | DNSSEC validation |
| Kaminsky attack | 0x20 encoding, DNSSEC |
| Side channels | Rate limiting, cookies |

### Defense Implementation
```yaml
# Unbound hardening
server:
    # Randomize query case (0x20 encoding)
    use-caps-for-id: yes

    # Limit queries to prevent amplification
    unwanted-reply-threshold: 10000000

    # DNSSEC validation
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    val-clean-additional: yes

    # Harden against various attacks
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-referral-path: yes
    harden-algo-downgrade: yes
    harden-below-nxdomain: yes
    harden-large-queries: yes
    harden-short-bufsize: yes
```

## DNS Amplification Attack Mitigation

### Server-Side (Authoritative)
```
# BIND - Response Rate Limiting
rate-limit {
    responses-per-second 10;
    referrals-per-second 5;
    nodata-per-second 5;
    nxdomains-per-second 5;
    errors-per-second 5;
    all-per-second 100;
    window 15;
    ipv4-prefix-length 24;
    ipv6-prefix-length 56;
};
```

### Network-Side
- BCP38/BCP84: Filter spoofed source IPs at edge
- Block UDP/53 inbound except to authorized resolvers
- Rate-limit DNS responses at firewall

## Modern DNS Tools

### q - Modern DNS Client
```bash
# Install
go install github.com/natesales/q@latest

# Basic query
q example.com A

# Multiple record types
q example.com A AAAA MX

# Encrypted DNS
q example.com --tls @1.1.1.1
q example.com --https @cloudflare-dns.com/dns-query
q example.com --quic @dns.adguard-dns.com

# JSON output
q example.com --format=json

# Trace resolution
q example.com --trace
```

### doggo
```bash
# Install
go install github.com/mr-karan/doggo/cmd/doggo@latest

# Basic query
doggo example.com A

# DoH query
doggo example.com --type=A --nameserver=https://cloudflare-dns.com/dns-query

# JSON output
doggo example.com -J

# Reverse lookup
doggo -x 8.8.8.8
```

### dnsx (Security/Recon Tool)
```bash
# Install
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest

# Resolve list of domains
cat domains.txt | dnsx -a -resp

# Find subdomains with specific records
cat subdomains.txt | dnsx -a -aaaa -cname -mx -txt -resp

# Check for wildcard
echo example.com | dnsx -wd

# JSON output
dnsx -d example.com -a -json
```

### massdns (High-Performance Bulk Resolution)
```bash
# Resolve 1M domains quickly
massdns -r resolvers.txt -t A -o S domains.txt > results.txt

# With rate limiting
massdns -r resolvers.txt -t A -s 10000 domains.txt
```

### Tool Comparison
| Tool | Best For | Encrypted DNS | Output Formats |
|------|----------|---------------|----------------|
| dig | General debugging | No | Text |
| kdig | DNSSEC/modern features | Yes (DoT/DoQ) | Text |
| q | Modern replacement for dig | Yes (all) | JSON, text |
| doggo | User-friendly queries | Yes (DoH/DoT) | JSON, table |
| dnsx | Bulk recon | No | JSON, text |
| massdns | High-volume resolution | No | Various |
