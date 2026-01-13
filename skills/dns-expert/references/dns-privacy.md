# DNS Privacy Protocols

## Evolution of Encrypted DNS
| Protocol | Port | RFC | Transport | Status |
|----------|------|-----|-----------|--------|
| DNS (classic) | 53 | 1035 | UDP/TCP | Standard |
| DNS over TLS (DoT) | 853 | 7858 | TLS | Deployed |
| DNS over HTTPS (DoH) | 443 | 8484 | HTTPS | Deployed |
| DNS over QUIC (DoQ) | 853 | 9250 | QUIC | Emerging |
| Oblivious DoH (ODoH) | 443 | 9230 | HTTPS | Emerging |
| DNS over Dedicated QUIC (DDR) | 443 | 9462 | QUIC | Emerging |

## DNS over QUIC (DoQ) - RFC 9250

### Advantages over DoT/DoH
- **0-RTT connection establishment**: Faster than TCP+TLS handshake
- **Multiplexed streams**: No head-of-line blocking
- **Connection migration**: Survives network changes
- **Native encryption**: QUIC includes TLS 1.3

### DoQ Wire Format
- Uses QUIC streams (one query per stream)
- 2-byte length prefix (like DNS over TCP)
- Port 853 (same as DoT, distinguished by ALPN `doq`)

### Client Configuration
```bash
# Using q (modern DNS client)
q example.com A --quic @dns.adguard-dns.com

# Using kdig with QUIC
kdig +quic @dns.adguard-dns.com example.com
```

### DoQ Providers
| Provider | Endpoint | ALPN |
|----------|----------|------|
| AdGuard | dns.adguard-dns.com:853 | doq |
| Cloudflare | cloudflare-dns.com:853 | doq |
| NextDNS | dns.nextdns.io:853 | doq |

## Oblivious DNS over HTTPS (ODoH) - RFC 9230

### Purpose
- **Separates client identity from queries**: Proxy sees client IP but not query content; target sees query but not client IP
- **Privacy enhancement**: Neither proxy nor target has full picture
- **Based on Oblivious HTTP (OHTTP)**: RFC 9458

### Architecture
```
Client → Proxy (Oblivious Relay) → Target (Resolver)
         [encrypted query blob]    [decrypts, resolves]

Client IP visible: YES              NO
Query visible:     NO               YES
```

### ODoH Flow
1. Client encrypts DNS query using target's public key
2. Client sends encrypted blob to proxy (relay)
3. Proxy forwards to target without seeing content
4. Target decrypts, resolves, encrypts response
5. Response flows back through proxy

### Configuration Discovery
- Target advertises public key via `/.well-known/odohconfigs`
- HTTPS record with `odoh` service parameter

### ODoH Providers
| Role | Provider | Endpoint |
|------|----------|----------|
| Target | Cloudflare | odoh.cloudflare-dns.com |
| Relay | Fastly | odoh.fastly-edge.com |
| Target | Apple | doh.dns.apple.com (via iCloud Private Relay) |

## DNS Discovery of Designated Resolvers (DDR) - RFC 9462

### Purpose
- Automatic upgrade from unencrypted to encrypted DNS
- Client discovers DoT/DoH/DoQ endpoints from IP address

### Discovery Process
```bash
# Query for _dns.resolver.arpa with SVCB record
dig _dns.resolver.arpa SVCB @192.0.2.1

# Response indicates encrypted endpoints
_dns.resolver.arpa. IN SVCB 1 dns.example.com. (
    alpn="h2,h3,doq" port=443
    dohpath="/dns-query{?dns}"
)
```

### SVCB Parameters for DDR
| Parameter | Description |
|-----------|-------------|
| alpn | Supported protocols (h2=DoH, h3=DoH/3, doq=DoQ) |
| port | Service port (443 for DoH, 853 for DoT/DoQ) |
| dohpath | URI template for DoH queries |
| ipv4hint/ipv6hint | Address hints for connection |

## Encrypted Client Hello (ECH) with DNS

### Purpose
- Encrypt SNI in TLS handshake (prevents SNI snooping)
- ECH configuration distributed via HTTPS records

### HTTPS Record with ECH
```zone
example.com. IN HTTPS 1 . alpn="h2,h3" ech="..."
```

### ECH Key Retrieval
```bash
# Fetch HTTPS record to get ECH config
dig +short example.com HTTPS
```

## Privacy Comparison Matrix

| Aspect | Plain DNS | DoT | DoH | DoQ | ODoH |
|--------|-----------|-----|-----|-----|------|
| Query encryption | No | Yes | Yes | Yes | Yes |
| Metadata protection | No | Partial | Better | Better | Best |
| Port distinguishable | N/A | Yes (853) | No (443) | Yes (853) | No (443) |
| Query-IP separation | No | No | No | No | Yes |
| Latency | Low | Medium | Medium | Low | Higher |

## Resolver Information (RFC 9606)

### RESINFO Record Type

The RESINFO record (type 261) allows resolvers to advertise their capabilities to clients.

### Purpose
- Discover resolver features (DNSSEC validation, ECS, QNAME minimization)
- Identify resolver software and version
- Learn about filtering/blocking policies
- Find extended resolver information

### RESINFO Query
```bash
# Query resolver for its information
dig @8.8.8.8 resolver.arpa RESINFO

# Response contains key=value pairs:
# qnamemin=true          - QNAME minimization enabled
# exterr=true            - Extended DNS Errors (EDE) supported
# infourl=https://...    - URL with resolver documentation
# dnssec=true            - DNSSEC validation enabled
```

### RESINFO Keys
| Key | Description |
|-----|-------------|
| qnamemin | QNAME minimization enabled |
| exterr | Extended DNS Errors (EDE) supported |
| infourl | URL for resolver documentation |
| dnssec | DNSSEC validation enabled |

### Resolver Information Discovery

```bash
# DDR + RESINFO combined workflow
# Step 1: Discover encrypted resolver endpoints
dig _dns.resolver.arpa SVCB @192.0.2.1

# Step 2: Query resolver capabilities
dig resolver.arpa RESINFO @192.0.2.1

# Step 3: Connect using discovered parameters
kdig +tls @dns.example.com example.com
```

## DELEG Record (Draft)

### Extensible Delegation Record

DELEG is an emerging record type (draft-ietf-dnsop-deleg) designed to modernize DNS delegation with extensible parameters.

### Motivation
- Current NS records are limited (just nameserver names)
- No way to signal delegation parameters (DNSSEC, transport, etc.)
- DELEG provides SVCB-like extensibility for delegations

### DELEG Record Format
```zone
; DELEG uses SVCB-style parameters
child.example.com. IN DELEG 1 ns1.example.com. (
    ipv4hint=192.0.2.1
    ipv6hint=2001:db8::1
    alpn="dot"
)
```

### DELEG vs NS
| Aspect | NS | DELEG |
|--------|-----|-------|
| Parameters | None | Extensible (like SVCB) |
| Transport hints | No | Yes (DoT, DoH, DoQ) |
| Address hints | Via glue (optional) | Built-in |
| DNSSEC info | Via DS | Can include DS info |

### Current Status
- IETF draft under active development
- Not yet assigned TYPE code
- Experimental implementations exist

## DNS64 (RFC 6147)

### IPv6 Transition Mechanism

DNS64 synthesizes AAAA records from A records for IPv6-only clients needing to reach IPv4-only servers.

### Architecture
```
                           NAT64 Gateway
IPv6-only Client → DNS64 → ─────────────── → IPv4 Server
                           (synthesizes AAAA)
```

### How DNS64 Works
1. Client queries AAAA for `example.com`
2. If no AAAA exists, DNS64 queries for A record
3. DNS64 synthesizes AAAA using NAT64 prefix (e.g., `64:ff9b::/96`)
4. Client connects to synthesized IPv6 address
5. NAT64 gateway translates to IPv4

### Example Synthesis
```
# Original A record
example.com. IN A 192.0.2.1

# DNS64 synthesizes (using 64:ff9b::/96 prefix)
example.com. IN AAAA 64:ff9b::192.0.2.1
# Which is: 64:ff9b::c000:201
```

### Unbound DNS64 Configuration
```yaml
server:
    module-config: "dns64 validator iterator"
    dns64-prefix: 64:ff9b::/96
    # Exclude these from synthesis (native IPv6)
    dns64-synthall: no
```

### BIND DNS64 Configuration
```
options {
    dns64 64:ff9b::/96 {
        clients { any; };
        mapped { !rfc1918; any; };
        exclude { 64:ff9b::/96; ::ffff:0:0/96; };
    };
};
```

## Public DNS Resolvers

| Provider | IPv4 | IPv6 | DoH | DoT | Features |
|----------|------|------|-----|-----|----------|
| Cloudflare | 1.1.1.1, 1.0.0.1 | 2606:4700:4700::1111 | cloudflare-dns.com/dns-query | cloudflare-dns.com:853 | Fast, privacy-focused |
| Google | 8.8.8.8, 8.8.4.4 | 2001:4860:4860::8888 | dns.google/dns-query | dns.google:853 | Global anycast |
| Quad9 | 9.9.9.9 | 2620:fe::fe | dns.quad9.net/dns-query | dns.quad9.net:853 | Malware blocking |
| OpenDNS | 208.67.222.222 | 2620:119:35::35 | doh.opendns.com/dns-query | — | Content filtering |
| AdGuard | 94.140.14.14 | 2a10:50c0::ad1:ff | dns.adguard-dns.com/dns-query | dns.adguard-dns.com:853 | Ad blocking |

### Testing Encrypted DNS
```bash
# DNS over TLS
kdig @1.1.1.1 +tls example.com

# DNS over HTTPS
curl -H 'accept: application/dns-json' \
  'https://cloudflare-dns.com/dns-query?name=example.com&type=A'

# Using dog (modern dig alternative)
dog example.com --tls @1.1.1.1
```
