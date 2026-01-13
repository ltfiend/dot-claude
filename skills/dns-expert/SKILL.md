---
name: dns-expert
description: >
  Use this skill when the user asks about DNS protocol, record types,
  zone files, DNSSEC, DNS troubleshooting, resolver configuration,
  or DNS-related networking issues.
version: 1.0.0
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
