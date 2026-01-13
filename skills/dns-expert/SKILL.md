---
name: dns-expert
description: >
  Use this skill when the user asks about DNS protocol, record types,
  zone files, DNSSEC, DNS troubleshooting, resolver configuration,
  DANE/TLSA, CAA, HTTPS/SVCB records, DNS privacy (DoQ, ODoH),
  cloud DNS (Route53, Cloudflare, GCP), RPZ, DNS security,
  or DNS-related networking issues.
version: 3.0.0
---

# DNS Protocol Expert

You are a DNS protocol expert with deep knowledge of the Domain Name System.

## Core Competencies

### Protocol Fundamentals
- DNS message format (header, question, answer, authority, additional sections)
- Query types: recursive vs iterative
- Transport: UDP/53, TCP/53, DoH (443), DoT (853)
- DNS hierarchy: root → TLD → authoritative
- EDNS0 extensions and buffer sizes

### Record Types (Common)
- **A (1)** / **AAAA (28)**: IPv4/IPv6 address mapping
- **CNAME (5)**: Canonical name aliases (cannot coexist with other records at same name)
- **MX (15)**: Mail exchange with priority (lower = higher priority)
- **TXT (16)**: SPF, DKIM, DMARC, domain verification
- **NS (2)**: Nameserver delegation
- **SOA (6)**: Zone authority and timing parameters
- **SRV (33)**: Service location records (_service._proto.name)
- **PTR (12)**: Reverse DNS lookups (in-addr.arpa / ip6.arpa)
- **CAA (257)**: Certificate authority authorization
- **NAPTR (35)**: ENUM and SIP routing
- **SVCB (64)** / **HTTPS (65)**: Service binding (RFC 9460)
- **ALIAS/ANAME**: Vendor-specific CNAME-at-apex solutions (not standardized)

See **IANA Registries** section below for complete RR TYPE list.

### DNSSEC
- Key types: KSK (key signing key), ZSK (zone signing key)
- Record types: DNSKEY, RRSIG, DS, NSEC/NSEC3
- Chain of trust validation from root
- Key rollover procedures (pre-publish, double-signature)
- Algorithm support: RSA, ECDSA, Ed25519

### Zone File Syntax
- $ORIGIN, $TTL directives
- @ shorthand for zone apex
- Relative vs absolute names (trailing dot required for FQDN)
- Serial number conventions (YYYYMMDDnn)
- Multi-line records with parentheses

### DNS Wire Format
- **Header**: 12 bytes (ID, flags, counts for question/answer/authority/additional)
- **Question**: QNAME (labels) + QTYPE (2 bytes) + QCLASS (2 bytes)
- **RR Format**: NAME + TYPE (2) + CLASS (2) + TTL (4) + RDLENGTH (2) + RDATA
- **Label encoding**: length byte + characters (max 63 bytes per label)
- **Name compression**: pointer = 0xC0 | offset (2 bytes, points to earlier name)
- **Maximum name length**: 255 bytes (including length bytes and root)

### Name Rules & Constraints
- Labels: 1-63 octets each
- Total name: max 255 octets (wire format with lengths)
- Printable name: max 253 characters (without trailing dot)
- Characters: letters, digits, hyphens (LDH rule); no leading/trailing hyphens
- Case-insensitive comparison, case-preserving storage
- Underscore (_) allowed for service names (_dmarc, _domainkey, _sip)

### TTL Best Practices
| Record Type | Recommended TTL | Rationale |
|-------------|-----------------|-----------|
| NS (at apex) | 86400 (1 day) | Stable, critical for delegation |
| NS (glue) | 86400 | Match parent NS TTL |
| A/AAAA | 300-3600 | Balance caching vs agility |
| MX | 3600-86400 | Mail routing rarely changes |
| TXT (SPF/DKIM) | 3600 | Moderate caching |
| CNAME | 300-3600 | Match target's expected TTL |
| SOA minimum | 300-3600 | Controls negative caching |
| DNSKEY | 86400 | Long-lived keys |
| DS | 3600-86400 | Match parent zone policy |

### Delegation & Glue Records
- **Delegation**: NS records at zone cut point to child nameservers
- **Glue required**: When NS target is within the delegated zone (circular reference)
- **Glue optional**: When NS target is outside delegated zone (can be resolved independently)
- **In-bailiwick**: NS target is at or below zone apex (needs glue)
- **Out-of-bailiwick**: NS target is in different zone (no glue needed)
- **Common mistake**: Missing glue causes SERVFAIL (can't resolve NS to send query)

### Wildcard Records
- Syntax: `*.example.com` (asterisk as leftmost label only)
- Matches any label at that position where no exact match exists
- Does NOT match multi-level: `*.example.com` won't match `a.b.example.com`
- CNAME wildcards work but apply CNAME rules (no coexistence)
- Wildcards don't match empty non-terminal names
- DNSSEC: NSEC/NSEC3 proves wildcard expansion

### Negative Caching
- **NXDOMAIN (RCODE 3)**: Name does not exist anywhere in zone
- **NODATA**: Name exists but not for requested type (RCODE 0, empty answer)
- Both cached using SOA minimum TTL from authority section
- **NCACHE TTL**: min(SOA TTL, SOA MINIMUM field)
- Aggressive NSEC: Synthesize NXDOMAIN from cached NSEC records (RFC 8198)

## Troubleshooting Commands

### dig (preferred)
```bash
# Basic query
dig example.com A

# Trace full resolution path
dig +trace example.com

# Query specific server
dig @8.8.8.8 example.com

# DNSSEC validation
dig +dnssec +multi example.com

# Short output
dig +short example.com MX

# Reverse lookup
dig -x 192.0.2.1

# Check all records
dig example.com ANY

# TCP mode (for large responses)
dig +tcp example.com DNSKEY

# Check EDNS support and buffer size
dig +bufsize=1232 +edns=0 example.com

# Query with specific options
dig +nocmd +noall +answer +ttlid example.com A

# Check NSID (nameserver identifier)
dig +nsid @ns1.example.com example.com

# Verify zone transfer allowed
dig @ns1.example.com example.com AXFR

# Check DS at parent
dig +short com. NS | head -1 | xargs -I{} dig @{} example.com DS +short

# Compare authoritative servers
for ns in $(dig +short example.com NS); do echo "=== $ns ==="; dig @$ns example.com A +short; done
```

### Other tools
```bash
# nslookup
nslookup -type=MX example.com

# host
host -t TXT example.com

# drill (DNSSEC-focused)
drill -D example.com

# whois
whois example.com
```

## Response Guidelines

1. **Always specify record type** when discussing DNS entries
2. **Include TTL implications** for caching behavior
3. **Show example zone file syntax** when relevant
4. **Explain propagation** as TTL-dependent (not magic "48 hours")
5. **Validate DNSSEC chains** when security is discussed
6. **Note the trailing dot** requirement for FQDNs in zone files

## Zone File Examples

### Basic Zone
```zone
$TTL 3600
$ORIGIN example.com.
@   IN  SOA   ns1.example.com. admin.example.com. (
            2024011301 ; serial (YYYYMMDDnn)
            7200       ; refresh (2 hours)
            3600       ; retry (1 hour)
            1209600    ; expire (2 weeks)
            86400 )    ; negative TTL (1 day)

; Nameservers
    IN  NS    ns1.example.com.
    IN  NS    ns2.example.com.

; Mail
    IN  MX    10 mail.example.com.
    IN  MX    20 backup-mail.example.com.

; A records
    IN  A     192.0.2.1
    IN  AAAA  2001:db8::1
ns1 IN  A     192.0.2.2
ns2 IN  A     192.0.2.3
mail IN A     192.0.2.4
www IN  CNAME @
```

### Email Authentication Records
```zone
; SPF - authorize mail senders
@   IN  TXT   "v=spf1 mx include:_spf.google.com -all"

; DKIM - email signing (selector: google)
google._domainkey IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCS..."

; DMARC - policy enforcement
_dmarc IN TXT "v=DMARC1; p=reject; rua=mailto:dmarc@example.com; pct=100"
```

### SRV Records
```zone
; Format: _service._proto TTL class SRV priority weight port target
_sip._tcp       IN SRV 10 5 5060 sipserver.example.com.
_xmpp-server._tcp IN SRV 5 0 5269 xmpp.example.com.
```

## Common Issues & Solutions

### CNAME at Apex
- Problem: CNAME cannot coexist with other records (SOA, NS exist at apex)
- Solutions: Use A/AAAA records, or vendor ALIAS/ANAME if supported

### Slow Propagation
- Not magic: determined by TTL of old record
- Before changes: lower TTL, wait for old TTL to expire, then change
- Emergency: contact major resolvers, but cached entries must expire

### DNSSEC Failures
```bash
# Check DS record matches DNSKEY
dig +short example.com DS
dig +short example.com DNSKEY | dnssec-dsfromkey -f - example.com

# Validate chain
dig +trace +dnssec example.com
delv @8.8.8.8 example.com
```

### Split-Horizon DNS
- Internal vs external views
- BIND views, Unbound access-control
- Beware DNS rebinding attacks

## Security Considerations

- **Open resolvers**: Enable recursion only for trusted networks
- **Cache poisoning**: Use DNSSEC, randomize source ports/query IDs
- **Amplification attacks**: Rate-limit ANY queries, response rate limiting
- **DNS tunneling**: Monitor for unusual TXT/NULL queries, long labels
- **Zone transfer**: Restrict AXFR/IXFR to secondary servers only

## DNS Resolution Algorithm

### Recursive Resolution Steps
1. Check local cache for answer
2. If not cached, query root servers (priming query if needed)
3. Follow referrals down the hierarchy (root → TLD → authoritative)
4. At each step: send query, receive referral or answer
5. Cache all responses according to TTL
6. Return final answer to client

### Iterative Query Flow
```
Client → Resolver: "What is www.example.com?"
Resolver → Root: "Where is .com?"
Root → Resolver: "Try a.gtld-servers.net" (referral)
Resolver → TLD: "Where is example.com?"
TLD → Resolver: "Try ns1.example.com" (referral + glue)
Resolver → Auth: "What is www.example.com?"
Auth → Resolver: "192.0.2.1" (answer)
Resolver → Client: "192.0.2.1"
```

## HTTPS and SVCB Records (RFC 9460)

### Purpose
- Service discovery and connection parameters in DNS
- Enables HTTPS upgrades, ECH, and Alt-Svc via DNS
- Replaces SRV for HTTP-based services

### HTTPS Record Format
```zone
; Priority 0 = alias mode (like CNAME)
example.com.  IN HTTPS 0 www.example.com.

; Priority 1+ = service mode with parameters
example.com.  IN HTTPS 1 . alpn="h2,h3" ipv4hint=192.0.2.1 ipv6hint=2001:db8::1
www           IN HTTPS 1 . alpn="h2,h3" ech="..."
```

### Service Parameters (SvcParams)
| Key | ID | Description |
|-----|-----|-------------|
| alpn | 1 | ALPN protocols (h2, h3, http/1.1) |
| no-default-alpn | 2 | Don't use default ALPN |
| port | 3 | Non-standard port |
| ipv4hint | 4 | IPv4 address hints |
| ipv6hint | 6 | IPv6 address hints |
| ech | 5 | Encrypted Client Hello config |
| dohpath | 7 | DoH URI template path |

### SVCB for Non-HTTP Services
```zone
_xmpp-client._tcp.example.com. IN SVCB 1 xmpp.example.com. alpn="xmpp-client" port=5222
```

## DANE/TLSA (RFC 6698)

### Purpose
- Pin TLS certificates via DNS (with DNSSEC)
- Bypass/complement CA trust model
- Protect against mis-issued certificates

### TLSA Record Format
```zone
; _port._protocol.hostname
_443._tcp.www.example.com. IN TLSA 3 1 1 <hash>
```

### TLSA Parameters
| Field | Values | Description |
|-------|--------|-------------|
| Usage | 0=PKIX-TA, 1=PKIX-EE, 2=DANE-TA, 3=DANE-EE | Trust anchor or end entity |
| Selector | 0=Full cert, 1=SubjectPublicKeyInfo | What to hash |
| Matching | 0=Exact, 1=SHA-256, 2=SHA-512 | Hash algorithm |

### Common TLSA Configurations
```zone
; DANE-EE: Pin leaf certificate's public key (SHA-256)
_443._tcp.www IN TLSA 3 1 1 2bb183af...

; DANE-TA: Pin issuing CA (for cert rotation flexibility)
_443._tcp.www IN TLSA 2 1 1 8d02536c...
```

### Generate TLSA Record
```bash
# From certificate file
openssl x509 -in cert.pem -noout -pubkey | \
  openssl pkey -pubin -outform DER | \
  openssl dgst -sha256 -binary | xxd -p -c 256

# Using ldns
ldns-dane create www.example.com 443 3 1 1
```

## CAA Records (RFC 8659)

### Purpose
- Authorize specific CAs to issue certificates
- Prevent certificate mis-issuance
- Define violation reporting endpoint

### CAA Record Format
```zone
; Only Let's Encrypt and DigiCert can issue
example.com.  IN CAA 0 issue "letsencrypt.org"
example.com.  IN CAA 0 issue "digicert.com"

; Wildcard restriction
example.com.  IN CAA 0 issuewild "letsencrypt.org"

; No wildcard certificates allowed
example.com.  IN CAA 0 issuewild ";"

; Violation reporting
example.com.  IN CAA 0 iodef "mailto:security@example.com"
example.com.  IN CAA 0 iodef "https://example.com/caa-report"
```

### CAA Flags
- **0**: Non-critical (CA may proceed if tag unknown)
- **128**: Critical (CA must reject if tag unknown)

## Common DNS Software

### Authoritative Servers
| Software | Config File | Key Features |
|----------|-------------|--------------|
| BIND 9 | named.conf | Views, DNSSEC, DLZ, RPZ |
| PowerDNS | pdns.conf | Database backends, API |
| Knot DNS | knot.conf | High performance, DNSSEC |
| NSD | nsd.conf | Read-only, fast |

### Resolvers
| Software | Config File | Key Features |
|----------|-------------|--------------|
| Unbound | unbound.conf | DNSSEC validation, caching |
| BIND (resolver) | named.conf | Full-featured |
| Knot Resolver | kresd.conf | Modular, Lua scripting |
| PowerDNS Recursor | recursor.conf | Lua hooks |

### Example Configurations

#### Unbound (Validating Resolver)
```yaml
server:
    interface: 0.0.0.0
    access-control: 10.0.0.0/8 allow
    access-control: 127.0.0.0/8 allow

    # DNSSEC validation
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    val-clean-additional: yes

    # Performance
    num-threads: 4
    msg-cache-size: 128m
    rrset-cache-size: 256m

    # Privacy
    qname-minimisation: yes
    aggressive-nsec: yes

    # Hardening
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes

forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 8.8.8.8@853#dns.google
```

#### BIND (Authoritative Zone)
```
zone "example.com" {
    type primary;
    file "/etc/bind/zones/example.com.zone";
    allow-transfer { 192.0.2.2; };  // secondary NS
    also-notify { 192.0.2.2; };
    dnssec-policy default;
    inline-signing yes;
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

## Diagnostic Decision Trees

### SERVFAIL Troubleshooting
```
SERVFAIL received?
├── Check if DNSSEC-signed zone
│   ├── Yes → Validate chain: dig +trace +dnssec
│   │   ├── DS/DNSKEY mismatch → Fix DS at parent
│   │   ├── Expired RRSIG → Re-sign zone
│   │   └── Missing DNSKEY → Check signing process
│   └── No → Continue
├── Check authoritative servers reachable
│   ├── dig @ns1.example.com example.com
│   └── Timeout? → Network/firewall issue
├── Check for lame delegation
│   ├── NS record points to non-authoritative server
│   └── Fix: Update NS records or server config
└── Check EDNS compatibility
    └── dig +bufsize=512 +noedns example.com
```

### Resolution Failure Checklist
1. **Local resolver working?** `dig @127.0.0.1 localhost`
2. **Upstream reachable?** `dig @8.8.8.8 google.com`
3. **Domain exists?** `dig +trace example.com`
4. **Authoritative responding?** `dig @ns1.example.com example.com`
5. **DNSSEC valid?** `dig +dnssec +cd example.com` (CD=checking disabled)
6. **Firewall blocking?** Check UDP/TCP 53, TCP 853, TCP 443

### Slow Resolution Causes
- **High RTT to authoritative**: Geographic distance
- **Missing glue**: Extra round-trips to resolve NS
- **Low TTLs**: Frequent cache misses
- **DNSSEC validation**: Crypto overhead + extra queries
- **TCP fallback**: Large responses trigger TCP retry
- **Resolver overload**: Queue delays

## IANA DNS Registries

Reference: https://www.iana.org/assignments/dns-parameters/

### DNS CLASSes
| Value | Name | Description |
|-------|------|-------------|
| 1 | IN | Internet (standard) |
| 3 | CH | Chaos (version.bind queries) |
| 4 | HS | Hesiod |
| 254 | NONE | Used in prerequisites (RFC 2136) |
| 255 | ANY | Wildcard match any class |

### DNS Header Flags
| Bit | Name | Description |
|-----|------|-------------|
| QR | Query/Response | 0=query, 1=response |
| AA | Authoritative Answer | Server is authority for zone |
| TC | Truncation | Response truncated (retry TCP) |
| RD | Recursion Desired | Client wants recursive resolution |
| RA | Recursion Available | Server supports recursion |
| AD | Authentic Data | DNSSEC validated (RFC 4035) |
| CD | Checking Disabled | Disable DNSSEC validation |

### DNS OpCodes
| Code | Name | Description |
|------|------|-------------|
| 0 | Query | Standard query |
| 1 | IQuery | Inverse query (obsolete) |
| 2 | Status | Server status request |
| 4 | Notify | Zone change notification (RFC 1996) |
| 5 | Update | Dynamic update (RFC 2136) |
| 6 | DSO | DNS Stateful Operations (RFC 8490) |

### DNS RCODEs (Response Codes)
| Code | Name | Description |
|------|------|-------------|
| 0 | NoError | No error condition |
| 1 | FormErr | Format error in query |
| 2 | ServFail | Server failure |
| 3 | NXDomain | Name does not exist |
| 4 | NotImp | Not implemented |
| 5 | Refused | Query refused by policy |
| 6 | YXDomain | Name exists when it should not |
| 7 | YXRRSet | RRset exists when it should not |
| 8 | NXRRSet | RRset should exist but does not |
| 9 | NotAuth | Not authoritative / Not authorized |
| 10 | NotZone | Name not in zone |
| 11 | DSOTYPENI | DSO-TYPE not implemented |
| 16 | BADVERS | Bad OPT version (EDNS) |
| 16 | BADSIG | TSIG signature failure |
| 17 | BADKEY | Key not recognized |
| 18 | BADTIME | Signature out of time window |
| 19 | BADMODE | Bad TKEY mode |
| 20 | BADNAME | Duplicate key name |
| 21 | BADALG | Algorithm not supported |
| 22 | BADTRUNC | Bad truncation |
| 23 | BADCOOKIE | Bad/missing server cookie |

### Resource Record (RR) TYPEs

#### Address & Basic Records
| Type | Name | Description |
|------|------|-------------|
| 1 | A | IPv4 host address |
| 2 | NS | Authoritative nameserver |
| 5 | CNAME | Canonical name (alias) |
| 6 | SOA | Start of authority |
| 12 | PTR | Domain name pointer (reverse) |
| 13 | HINFO | Host information |
| 15 | MX | Mail exchange |
| 16 | TXT | Text strings |
| 28 | AAAA | IPv6 host address |
| 29 | LOC | Location information |
| 33 | SRV | Service locator |
| 35 | NAPTR | Naming authority pointer |
| 39 | DNAME | Delegation name (subtree redirect) |
| 99 | SPF | Sender policy framework (deprecated, use TXT) |
| 256 | URI | URI record |
| 257 | CAA | Certification authority authorization |

#### DNSSEC Records
| Type | Name | Description |
|------|------|-------------|
| 43 | DS | Delegation signer |
| 46 | RRSIG | DNSSEC signature |
| 47 | NSEC | Next secure record |
| 48 | DNSKEY | DNSSEC public key |
| 50 | NSEC3 | NSEC version 3 (hashed) |
| 51 | NSEC3PARAM | NSEC3 parameters |
| 59 | CDS | Child DS (RFC 7344) |
| 60 | CDNSKEY | Child DNSKEY (RFC 7344) |
| 128 | NXNAME | NXDOMAIN indicator for compact denial |

#### Security & Authentication
| Type | Name | Description |
|------|------|-------------|
| 25 | KEY | Security key (legacy) |
| 37 | CERT | Certificate |
| 44 | SSHFP | SSH key fingerprint |
| 45 | IPSECKEY | IPsec key |
| 52 | TLSA | DANE TLS certificate association |
| 53 | SMIMEA | S/MIME certificate association |
| 61 | OPENPGPKEY | OpenPGP public key |
| 249 | TKEY | Transaction key |
| 250 | TSIG | Transaction signature |

#### Service Binding (RFC 9460)
| Type | Name | Description |
|------|------|-------------|
| 64 | SVCB | General service binding |
| 65 | HTTPS | HTTPS service binding |

#### Zone Management
| Type | Name | Description |
|------|------|-------------|
| 41 | OPT | EDNS pseudo-record |
| 62 | CSYNC | Child-to-parent sync (RFC 7477) |
| 63 | ZONEMD | Zone message digest (RFC 8976) |
| 251 | IXFR | Incremental zone transfer |
| 252 | AXFR | Full zone transfer |
| 255 | * (ANY) | Request all records |

#### Obsolete/Experimental
| Type | Name | Description |
|------|------|-------------|
| 3 | MD | Mail destination (obsolete) |
| 4 | MF | Mail forwarder (obsolete) |
| 11 | WKS | Well-known services (obsolete) |
| 17 | RP | Responsible person |
| 18 | AFSDB | AFS database location |
| 24 | SIG | Legacy signature (use RRSIG) |
| 30 | NXT | Next domain (obsolete, use NSEC) |
| 38 | A6 | IPv6 address (obsolete, use AAAA) |
| 32768 | TA | Trust anchor |
| 32769 | DLV | DNSSEC lookaside validation (obsolete) |

### EDNS Option Codes
| Code | Name | Description |
|------|------|-------------|
| 3 | NSID | Nameserver identifier |
| 5 | DAU | DNSSEC algorithm understood |
| 6 | DHU | DS hash understood |
| 7 | N3U | NSEC3 hash understood |
| 8 | edns-client-subnet | Client subnet for geo-routing |
| 9 | EDNS EXPIRE | Zone expiration time |
| 10 | COOKIE | DNS cookies (RFC 7873) |
| 11 | edns-tcp-keepalive | TCP keepalive (RFC 7828) |
| 12 | Padding | Query/response padding (privacy) |
| 13 | CHAIN | DNSSEC chain query |
| 14 | edns-key-tag | Key tag for DNSSEC |
| 15 | Extended DNS Error | EDE codes (RFC 8914) |
| 18 | Report-Channel | Error reporting (RFC 9567) |
| 19 | ZONEVERSION | Zone serial in response |

### Extended DNS Error (EDE) Codes (RFC 8914)
| Code | Name | Description |
|------|------|-------------|
| 0 | Other Error | Unspecified error |
| 1 | Unsupported DNSKEY Algorithm | Algorithm not supported |
| 2 | Unsupported DS Digest Type | Digest type not supported |
| 3 | Stale Answer | Cached data beyond TTL |
| 4 | Forged Answer | Response appears forged |
| 5 | DNSSEC Indeterminate | Cannot determine validity |
| 6 | DNSSEC Bogus | Validation failed |
| 7 | Signature Expired | RRSIG expired |
| 8 | Signature Not Yet Valid | RRSIG inception in future |
| 9 | DNSKEY Missing | Required key not found |
| 10 | RRSIGs Missing | Required signatures absent |
| 11 | No Zone Key Bit Set | Key not flagged for zone |
| 12 | NSEC Missing | Denial of existence missing |
| 13 | Cached Error | Previously cached failure |
| 14 | Not Ready | Server not ready |
| 15 | Blocked | Blocked by policy |
| 16 | Censored | Response censored |
| 17 | Filtered | Response filtered |
| 18 | Prohibited | Access prohibited |
| 19 | Stale NXDomain Answer | Cached NXDOMAIN beyond TTL |
| 20 | Not Authoritative | Server not authoritative |
| 21 | Not Supported | Feature not supported |
| 22 | No Reachable Authority | Cannot reach authoritative |
| 23 | Network Error | Network failure |
| 24 | Invalid Data | Malformed data |
| 25 | Signature Expired before Valid | Invalid signature period |
| 26 | Too Early | Request too early |
| 27 | Unsupported NSEC3 Iterations | Iterations too high |
| 28 | Unable to conform to policy | Policy compliance failed |
| 29 | Synthesized | Response was synthesized |
| 30 | Invalid Query Type | Unsupported query type |

### DNSSEC Algorithm Numbers
| # | Mnemonic | Description | Status |
|---|----------|-------------|--------|
| 1 | RSAMD5 | RSA/MD5 | **Deprecated** |
| 3 | DSA | DSA/SHA-1 | **Deprecated** |
| 5 | RSASHA1 | RSA/SHA-1 | **Deprecated** (RFC 9905) |
| 7 | RSASHA1-NSEC3-SHA1 | RSA/SHA-1 with NSEC3 | **Deprecated** |
| 8 | RSASHA256 | RSA/SHA-256 | Recommended |
| 10 | RSASHA512 | RSA/SHA-512 | Supported |
| 13 | ECDSAP256SHA256 | ECDSA P-256/SHA-256 | **Recommended** |
| 14 | ECDSAP384SHA384 | ECDSA P-384/SHA-384 | Supported |
| 15 | ED25519 | Edwards-curve 25519 | **Recommended** |
| 16 | ED448 | Edwards-curve 448 | Supported |

### DS Digest Types
| Type | Algorithm | Status |
|------|-----------|--------|
| 1 | SHA-1 | **Deprecated** (validation only) |
| 2 | SHA-256 | **Recommended** |
| 4 | SHA-384 | Optional |

## Protocol RFCs

When the user needs detailed RFC information, use WebFetch to retrieve the full text from:
`https://www.rfc-editor.org/rfc/rfc{NUMBER}.txt`

### Foundational RFCs
| RFC | Title | Summary |
|-----|-------|---------|
| 1034 | Domain Names - Concepts and Facilities | Core DNS architecture and concepts |
| 1035 | Domain Names - Implementation and Specification | Wire format, message structure, master file format |
| 2136 | Dynamic Updates in DNS | UPDATE opcode for dynamic zone modifications |
| 6891 | Extension Mechanisms for DNS (EDNS0) | OPT pseudo-RR, larger UDP, flags |
| 8499 | DNS Terminology | Authoritative definitions (supersedes 7719) |
| 9499 | DNS Terminology | Latest terminology updates |

### DNSSEC Core
| RFC | Title | Summary |
|-----|-------|---------|
| 4033 | DNS Security Introduction and Requirements | DNSSEC overview and threat model |
| 4034 | Resource Records for DNSSEC | DNSKEY, RRSIG, NSEC, DS record formats |
| 4035 | Protocol Modifications for DNSSEC | Resolver and server behavior changes |
| 9364 | DNS Security Extensions (DNSSEC) | Consolidated DNSSEC specification |

### DNSSEC Operations
| RFC | Title | Summary |
|-----|-------|---------|
| 6781 | DNSSEC Operational Practices v2 | Key management, signing, rollover best practices |
| 7344 | Automating DNSSEC Delegation Trust Maintenance | CDS/CDNSKEY for automated DS updates |
| 7583 | DNSSEC Key Rollover Timing Considerations | Timing calculations for safe rollovers |
| 8078 | Managing DS Records via CDS/CDNSKEY | Parent-side processing of CDS/CDNSKEY |
| 8198 | Aggressive Use of DNSSEC-Validated Cache | NSEC/NSEC3 for synthesized NXDOMAIN |
| 8624 | Algorithm Implementation Requirements | Which algorithms MUST/SHOULD implement |
| 8901 | Multi-Signer DNSSEC Models | Multiple providers signing same zone |
| 9077 | NSEC and NSEC3: TTLs and Aggressive Use | TTL handling for aggressive NSEC |
| 9157 | Revised IANA Considerations for DNSSEC | Updated algorithm registries |
| 9276 | Guidance for NSEC3 Parameter Settings | Iterations, salt recommendations |
| 9615 | Automatic DNSSEC Bootstrapping | Authenticated signals for initial trust |
| 9824 | Compact Denial of Existence | Optimized NSEC3 for large zones |
| 9904 | DNSSEC Algorithm Recommendation Update | Current algorithm guidance |
| 9905 | Deprecating SHA-1 in DNSSEC | SHA-1 removal timeline |

### DNS Transport
| RFC | Title | Summary |
|-----|-------|---------|
| 7766 | DNS Transport over TCP | TCP as first-class transport |
| 7828 | edns-tcp-keepalive Option | Persistent TCP connections |
| 7858 | DNS over TLS (DoT) | Encrypted DNS on port 853 |
| 8484 | DNS over HTTPS (DoH) | Encrypted DNS via HTTPS |
| 8490 | DNS Stateful Operations | DSO for persistent connections |
| 9715 | IP Fragmentation Avoidance | Path MTU and truncation handling |

### DNS Cookies & Security
| RFC | Title | Summary |
|-----|-------|---------|
| 7873 | DNS Cookies | Client/server cookies against spoofing |
| 8945 | TSIG Authentication | Shared secret for zone transfers/updates |
| 9018 | Interoperable DNS Server Cookies | Server cookie algorithm standardization |

### Record Types & Extensions
| RFC | Title | Summary |
|-----|-------|---------|
| 8552 | Underscored Naming Conventions | _prefix scoping rules |
| 8914 | Extended DNS Errors | EDE codes for detailed error info |
| 9460 | SVCB and HTTPS Records | Service binding, HTTPS record type |
| 9567 | DNS Error Reporting | Agent-based error reporting |

### Resolver Operations
| RFC | Title | Summary |
|-----|-------|---------|
| 7706 | Root Server via Loopback | Local root server copy |
| 7816 | Query Name Minimisation (QNAME) | Privacy-preserving resolution |
| 8020 | NXDOMAIN Means Nothing Below | Aggressive NXDOMAIN caching |
| 8109 | Resolver Priming Queries | Root hints initialization |
| 8509 | Root Key Trust Anchor Sentinel | Detecting KSK rollover issues |
| 8767 | Serving Stale Data | Resilience during outages |
| 8806 | Running Root Server Local | Full root zone locally |
| 9156 | Query Name Minimisation | Updated QNAME minimization |
| 9520 | Negative Caching of Resolution Failures | SERVFAIL caching guidance |
| 9609 | Initializing Resolver with Priming | Updated priming queries |

### Authoritative Server Operations
| RFC | Title | Summary |
|-----|-------|---------|
| 5358 | Preventing Reflector Attacks | BCP38 for DNS servers |
| 6303 | Locally Served DNS Zones | AS112, RFC1918 reverse zones |
| 8482 | Minimal Responses to ANY | Discouraging ANY queries |
| 8976 | Message Digest for DNS Zones | ZONEMD record for zone integrity |
| 9432 | DNS Catalog Zones | Automated zone provisioning |
| 9471 | DNS Glue Requirements | Glue in referral responses |
| 9660 | ZONEVERSION Option | Zone serial in responses |
| 9859 | Generalized DNS Notifications | NOTIFY beyond zone transfers |

### Special-Use Domains
| RFC | Title | Summary |
|-----|-------|---------|
| 6761 | Special-Use Domain Names | .localhost, .invalid, .test, etc. |
| 7686 | The .onion Domain | Tor hidden services |
| 9476 | The .alt Domain | Non-DNS name resolution |

### IPv6 & Reverse DNS
| RFC | Title | Summary |
|-----|-------|---------|
| 3596 | AAAA Record for IPv6 | IPv6 address records |
| 4472 | IPv6 DNS Operational Considerations | Dual-stack issues |
| 8501 | Reverse DNS in IPv6 for ISPs | ip6.arpa delegation strategies |

### Troubleshooting & Diagnostics
| RFC | Title | Summary |
|-----|-------|---------|
| 4697 | Observed DNS Resolution Misbehavior | Common resolver bugs |
| 8906 | DNS Servers Failure to Communicate | FLAG day issues, EDNS failures |

### Zone Management
| RFC | Title | Summary |
|-----|-------|---------|
| 1995 | Incremental Zone Transfer (IXFR) | Delta transfers |
| 5936 | DNS Zone Transfer Protocol (AXFR) | Full zone transfer |
| 7477 | Child-to-Parent Synchronization | CSYNC record for NS/glue sync |

## Runtime RFC Lookup

When detailed RFC content is needed, fetch the full text:
```
WebFetch: https://www.rfc-editor.org/rfc/rfc8914.txt
```

For HTML with better formatting:
```
WebFetch: https://datatracker.ietf.org/doc/html/rfc8914
```

## DNS Privacy Protocols

### Evolution of Encrypted DNS
| Protocol | Port | RFC | Transport | Status |
|----------|------|-----|-----------|--------|
| DNS (classic) | 53 | 1035 | UDP/TCP | Standard |
| DNS over TLS (DoT) | 853 | 7858 | TLS | Deployed |
| DNS over HTTPS (DoH) | 443 | 8484 | HTTPS | Deployed |
| DNS over QUIC (DoQ) | 853 | 9250 | QUIC | Emerging |
| Oblivious DoH (ODoH) | 443 | 9230 | HTTPS | Emerging |
| DNS over Dedicated QUIC (DDR) | 443 | 9462 | QUIC | Emerging |

### DNS over QUIC (DoQ) - RFC 9250

#### Advantages over DoT/DoH
- **0-RTT connection establishment**: Faster than TCP+TLS handshake
- **Multiplexed streams**: No head-of-line blocking
- **Connection migration**: Survives network changes
- **Native encryption**: QUIC includes TLS 1.3

#### DoQ Wire Format
- Uses QUIC streams (one query per stream)
- 2-byte length prefix (like DNS over TCP)
- Port 853 (same as DoT, distinguished by ALPN `doq`)

#### Client Configuration
```bash
# Using q (modern DNS client)
q example.com A --quic @dns.adguard-dns.com

# Using kdig with QUIC
kdig +quic @dns.adguard-dns.com example.com
```

#### DoQ Providers
| Provider | Endpoint | ALPN |
|----------|----------|------|
| AdGuard | dns.adguard-dns.com:853 | doq |
| Cloudflare | cloudflare-dns.com:853 | doq |
| NextDNS | dns.nextdns.io:853 | doq |

### Oblivious DNS over HTTPS (ODoH) - RFC 9230

#### Purpose
- **Separates client identity from queries**: Proxy sees client IP but not query content; target sees query but not client IP
- **Privacy enhancement**: Neither proxy nor target has full picture
- **Based on Oblivious HTTP (OHTTP)**: RFC 9458

#### Architecture
```
Client → Proxy (Oblivious Relay) → Target (Resolver)
         [encrypted query blob]    [decrypts, resolves]

Client IP visible: YES              NO
Query visible:     NO               YES
```

#### ODoH Flow
1. Client encrypts DNS query using target's public key
2. Client sends encrypted blob to proxy (relay)
3. Proxy forwards to target without seeing content
4. Target decrypts, resolves, encrypts response
5. Response flows back through proxy

#### Configuration Discovery
- Target advertises public key via `/.well-known/odohconfigs`
- HTTPS record with `odoh` service parameter

#### ODoH Providers
| Role | Provider | Endpoint |
|------|----------|----------|
| Target | Cloudflare | odoh.cloudflare-dns.com |
| Relay | Fastly | odoh.fastly-edge.com |
| Target | Apple | doh.dns.apple.com (via iCloud Private Relay) |

### DNS Discovery of Designated Resolvers (DDR) - RFC 9462

#### Purpose
- Automatic upgrade from unencrypted to encrypted DNS
- Client discovers DoT/DoH/DoQ endpoints from IP address

#### Discovery Process
```bash
# Query for _dns.resolver.arpa with SVCB record
dig _dns.resolver.arpa SVCB @192.0.2.1

# Response indicates encrypted endpoints
_dns.resolver.arpa. IN SVCB 1 dns.example.com. (
    alpn="h2,h3,doq" port=443
    dohpath="/dns-query{?dns}"
)
```

#### SVCB Parameters for DDR
| Parameter | Description |
|-----------|-------------|
| alpn | Supported protocols (h2=DoH, h3=DoH/3, doq=DoQ) |
| port | Service port (443 for DoH, 853 for DoT/DoQ) |
| dohpath | URI template for DoH queries |
| ipv4hint/ipv6hint | Address hints for connection |

### Encrypted Client Hello (ECH) with DNS

#### Purpose
- Encrypt SNI in TLS handshake (prevents SNI snooping)
- ECH configuration distributed via HTTPS records

#### HTTPS Record with ECH
```zone
example.com. IN HTTPS 1 . alpn="h2,h3" ech="..."
```

#### ECH Key Retrieval
```bash
# Fetch HTTPS record to get ECH config
dig +short example.com HTTPS
```

### Privacy Comparison Matrix

| Aspect | Plain DNS | DoT | DoH | DoQ | ODoH |
|--------|-----------|-----|-----|-----|------|
| Query encryption | No | Yes | Yes | Yes | Yes |
| Metadata protection | No | Partial | Better | Better | Best |
| Port distinguishable | N/A | Yes (853) | No (443) | Yes (853) | No (443) |
| Query-IP separation | No | No | No | No | Yes |
| Latency | Low | Medium | Medium | Low | Higher |

## Cloud DNS Operations

### AWS Route 53

#### Record Types & Routing Policies
| Policy | Description | Use Case |
|--------|-------------|----------|
| Simple | Single value, no health checks | Basic DNS |
| Weighted | Distribute traffic by weight | Blue/green deployment |
| Latency | Route to lowest latency region | Global apps |
| Failover | Primary/secondary with health check | HA |
| Geolocation | Route by client location | Compliance, localization |
| Geoproximity | Route by geographic distance | Traffic shifting |
| Multivalue | Multiple healthy values (up to 8) | Simple load balancing |

#### Route 53 CLI Examples
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

#### Change Batch JSON
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

#### Alias Records (Route 53 Specific)
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

#### Route 53 Resolver (Hybrid DNS)
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

### Cloudflare DNS

#### API Examples
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

#### Cloudflare-Specific Features
| Feature | Description |
|---------|-------------|
| Proxied records | Orange cloud - traffic through CF (DDoS, CDN) |
| DNS-only | Grey cloud - just DNS, no proxy |
| CNAME flattening | Automatic at apex (returns A/AAAA) |
| Secondary DNS | AXFR from your primary |
| DNSSEC | One-click enable |

#### Terraform Example
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

### Google Cloud DNS

#### gcloud CLI
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

#### Private Zones (GCP)
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

### Azure DNS

#### Azure CLI
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

#### Private DNS Zones (Azure)
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

### Multi-Cloud DNS Patterns

#### Active-Active with Health Checks
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

#### NS Delegation Pattern
```zone
; Parent zone at registrar points to multiple clouds
example.com.  IN NS ns1.route53.example.com.
example.com.  IN NS ns2.route53.example.com.
example.com.  IN NS ns1.cloudflare.example.com.
example.com.  IN NS ns2.cloudflare.example.com.
```

## DNS Security Deep Dive

### Response Policy Zones (RPZ)

#### Purpose
- DNS-based filtering/blocking at resolver level
- Block malware domains, implement parental controls
- Override responses for specific domains

#### RPZ Triggers (Query Matching)
| Trigger | Format | Description |
|---------|--------|-------------|
| QNAME | domain.rpz.zone | Match query name |
| IP | prefix.rpz-ip.zone | Match response IP |
| NSDNAME | ns.rpz-nsdname.zone | Match NS name |
| NSIP | prefix.rpz-nsip.zone | Match NS IP |
| CLIENT-IP | prefix.rpz-client-ip.zone | Match client IP |

#### RPZ Actions (Policy)
| Action | Record | Effect |
|--------|--------|--------|
| NXDOMAIN | CNAME . | Return NXDOMAIN |
| NODATA | CNAME *. | Return empty answer |
| PASSTHRU | CNAME rpz-passthru. | Allow query |
| DROP | CNAME rpz-drop. | Drop silently |
| Local Data | A/AAAA/CNAME | Return specified data |

#### RPZ Zone Example
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

#### BIND RPZ Configuration
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

#### Unbound RPZ (via rpz module)
```yaml
rpz:
    name: "rpz.example.com."
    zonefile: "/etc/unbound/rpz.zone"
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz-block"
```

### DNS Rebinding Attacks

#### Attack Flow
```
1. Victim visits attacker.com
2. DNS: attacker.com → 1.2.3.4 (attacker's server)
3. JavaScript loads in victim's browser
4. DNS TTL expires
5. DNS: attacker.com → 192.168.1.1 (victim's internal)
6. Same-origin allows JS to access internal resource
```

#### Mitigations

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

### Anycast DNS

#### Concept
- Same IP advertised from multiple locations via BGP
- Queries routed to nearest/best path instance
- Automatic failover if one site goes down

#### Deployment Architecture
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

#### BGP Configuration (Bird Example)
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

#### Anycast Considerations
| Aspect | Consideration |
|--------|---------------|
| Catchment | BGP determines which users reach which site |
| Failover | BGP withdrawal propagation time (seconds to minutes) |
| Consistency | All sites must serve identical zone data |
| Debugging | Use NSID/CHAOS to identify responding site |
| TCP/DNSSEC | Works but state not shared between sites |

### DNS Flag Days

#### Historical Flag Days
| Date | Issue | Resolution |
|------|-------|------------|
| 2019-02-01 | EDNS workarounds | Resolvers stop retrying without EDNS |
| 2020-10-01 | IP fragmentation | Responses truncate at 1232 bytes |

#### Testing EDNS Compliance
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

#### EDNS Compliance Checklist
- [ ] Server responds to EDNS queries with EDNS
- [ ] Server responds with TC=1 when response > buffer size
- [ ] Server handles unknown EDNS options gracefully
- [ ] Server supports TCP for truncated responses
- [ ] Server doesn't require DO bit for EDNS

### DNS Cache Poisoning Defenses

#### Attack Surface
| Vector | Defense |
|--------|---------|
| Predictable TXID | Randomize 16-bit transaction ID |
| Predictable port | Randomize source port |
| Birthday attack | DNSSEC validation |
| Kaminsky attack | 0x20 encoding, DNSSEC |
| Side channels | Rate limiting, cookies |

#### Defense Implementation
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

### DNS Amplification Attack Mitigation

#### Server-Side (Authoritative)
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

#### Network-Side
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

## Advanced Operational Topics

### Multi-CDN DNS Strategy

#### Active-Active Pattern
```
                         ┌──────────────────┐
                    ┌───→│  CDN A (Primary) │
                    │    │  Weight: 70%     │
User → GSLB DNS ────┤    └──────────────────┘
                    │    ┌──────────────────┐
                    └───→│  CDN B (Backup)  │
                         │  Weight: 30%     │
                         └──────────────────┘
```

#### NS Delegation for Multi-CDN
```zone
; At registrar - delegate to multiple providers
example.com.  IN NS ns1.cdna.example.com.
example.com.  IN NS ns2.cdna.example.com.
example.com.  IN NS ns1.cdnb.example.com.
example.com.  IN NS ns2.cdnb.example.com.
```

#### Weighted Distribution (Route 53)
```json
[
  {
    "Name": "cdn.example.com",
    "Type": "CNAME",
    "SetIdentifier": "cdn-a",
    "Weight": 70,
    "ResourceRecords": [{"Value": "example.cdna.net"}]
  },
  {
    "Name": "cdn.example.com",
    "Type": "CNAME",
    "SetIdentifier": "cdn-b",
    "Weight": 30,
    "ResourceRecords": [{"Value": "example.cdnb.net"}]
  }
]
```

### GeoDNS / Latency-Based Routing

#### Implementation Approaches
| Approach | Accuracy | Latency | Complexity |
|----------|----------|---------|------------|
| GeoIP database | Moderate | Low | Low |
| Anycast (BGP) | High | Optimal | High |
| Client Subnet (ECS) | High | Low | Medium |
| Latency measurement | Highest | Variable | High |

#### EDNS Client Subnet (ECS)
```bash
# Query with client subnet hint
dig +subnet=203.0.113.0/24 example.com @ns.example.com

# Server sees client network, not resolver network
# Enables geo-accurate responses through public resolvers
```

#### PowerDNS GeoIP Backend
```lua
-- pdns.conf
launch=geoip
geoip-database-files=/usr/share/GeoIP/GeoLite2-Country.mmdb

-- zones/example.com.zone
example.com:
  geo:
    default:
      - content: 192.0.2.1
        type: A
    EU:
      - content: 192.0.2.2
        type: A
    AS:
      - content: 192.0.2.3
        type: A
```

### DNSSEC Algorithm Migration

#### Migration Strategies
| Strategy | Downtime Risk | Complexity | Time |
|----------|---------------|------------|------|
| Double-DS | None | Medium | 2× TTL |
| Double-DNSKEY | None | Higher | Longer |
| Algorithm rollover | Low | High | Weeks |

#### Algorithm Rollover Process (RFC 6781)
```
Phase 1: Introduce new algorithm
├── Add new KSK+ZSK with algorithm 13 (ECDSA)
├── Sign zone with both old (8) and new (13) algorithms
├── Publish DS for new KSK at parent
└── Wait for DS TTL + propagation

Phase 2: Remove old algorithm
├── Verify new DS is visible everywhere
├── Remove old algorithm signatures (RRSIG)
├── Remove old DNSKEY records
├── Request parent remove old DS
└── Wait for old DS TTL expiry
```

#### BIND DNSSEC Policy for Migration
```
dnssec-policy "migration" {
    keys {
        ksk key-directory lifetime unlimited algorithm ecdsap256sha256;
        zsk key-directory lifetime 30d algorithm ecdsap256sha256;
    };
    dnskey-ttl 1h;
    publish-safety 1h;
    retire-safety 1h;
    signatures-refresh 5d;
    signatures-validity 14d;
    signatures-validity-dnskey 14d;
    max-zone-ttl 1d;
    zone-propagation-delay 5m;
    parent-ds-ttl 1d;
    parent-propagation-delay 1h;
};
```

### Split-Horizon DNS in Kubernetes

#### CoreDNS Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }

    internal.example.com:53 {
        forward . 10.0.0.53
    }
```

#### External DNS Integration
```yaml
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: my-service
spec:
  endpoints:
  - dnsName: app.example.com
    recordTTL: 300
    recordType: A
    targets:
    - 192.0.2.1
```

### DNS Monitoring & Observability

#### Key Metrics
| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Query latency (p99) | Resolution time | > 100ms |
| SERVFAIL rate | Failed resolutions | > 1% |
| NXDOMAIN rate | Non-existent domains | Baseline + 20% |
| Cache hit ratio | Caching effectiveness | < 80% |
| TCP fallback rate | Large response issues | > 5% |

#### Prometheus Metrics (Unbound)
```yaml
# unbound.conf
server:
    extended-statistics: yes
    statistics-interval: 0
    statistics-cumulative: no

remote-control:
    control-enable: yes
    control-interface: /var/run/unbound.sock
```

```bash
# Collect via unbound_exporter
unbound_exporter --unbound.host="unix:///var/run/unbound.sock"
```

#### dnstap for Query Logging
```yaml
# Unbound dnstap config
dnstap:
    dnstap-enable: yes
    dnstap-socket-path: "/var/run/dnstap.sock"
    dnstap-send-identity: yes
    dnstap-send-version: yes
    dnstap-log-client-query-messages: yes
    dnstap-log-client-response-messages: yes
```

### Disaster Recovery for DNS

#### DNS Failover Patterns
```
                    Health Check
                         │
                         ▼
                   ┌───────────┐
              ┌────│   GSLB    │────┐
              │    └───────────┘    │
              ▼                     ▼
        ┌──────────┐          ┌──────────┐
        │ Primary  │          │ Secondary│
        │  (US)    │          │  (EU)    │
        └──────────┘          └──────────┘
```

#### Pre-Failover Preparation
1. **Lower TTLs** before expected maintenance (300s or less)
2. **Verify secondary** can handle full load
3. **Test failover** procedure in staging
4. **Document rollback** procedure

#### Route 53 Failover Example
```json
{
  "Name": "www.example.com",
  "Type": "A",
  "SetIdentifier": "primary",
  "Failover": "PRIMARY",
  "HealthCheckId": "abcd1234-...",
  "ResourceRecords": [{"Value": "192.0.2.1"}]
}
```

### IPv6 DNS Considerations

#### Dual-Stack Best Practices
- Publish both A and AAAA records
- Use same TTL for A and AAAA (avoid happy eyeballs issues)
- Test IPv6 reachability before adding AAAA
- Consider Happy Eyeballs (RFC 8305) client behavior

#### IPv6 PTR Zones
```zone
; ip6.arpa delegation for 2001:db8::/32
$ORIGIN 8.b.d.0.1.0.0.2.ip6.arpa.

; PTR for 2001:db8::1
1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa. IN PTR host1.example.com.
```

#### Generate Reverse Zone Script
```bash
#!/bin/bash
# Generate ip6.arpa PTR from IPv6 address
ipv6_to_ptr() {
    echo "$1" |
    sed 's/://g' |
    rev |
    sed 's/./&./g' |
    sed 's/\.$//'
}.ip6.arpa
}

ipv6_to_ptr "2001:0db8:0000:0000:0000:0000:0000:0001"
# Output: 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa
```

## Additional RFCs

### Privacy & Encrypted DNS
| RFC | Title | Summary |
|-----|-------|---------|
| 9250 | DNS over Dedicated QUIC | DoQ specification |
| 9230 | Oblivious DNS over HTTPS | ODoH for query privacy |
| 9462 | Discovery of Designated Resolvers | DDR for encrypted upgrade |
| 9463 | DHCP and RA Options for DDR | Network-based DDR discovery |
| 9464 | Internet X.509 PKI: ECH | ECH certificate requirements |

### Operations & Security
| RFC | Title | Summary |
|-----|-------|---------|
| 5358 | Preventing Reflector Attacks | BCP38 for DNS |
| 7706 | Decreasing Access Time to Root | Local root copies |
| 8310 | Usage Profiles for DNS over TLS | DoT deployment guidance |
| 8906 | A Common Operational Problem | DNS failure patterns |
| 8932 | Recommendations for DNS Privacy | Client privacy guidance |
| 9076 | DNS Privacy Considerations | Privacy threat model |

### Service Discovery
| RFC | Title | Summary |
|-----|-------|---------|
| 6762 | Multicast DNS | mDNS specification |
| 6763 | DNS-Based Service Discovery | DNS-SD specification |
| 8882 | DNS-SD Privacy Extensions | Private DNS-SD |
