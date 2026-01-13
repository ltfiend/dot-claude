# IANA DNS Registries

Reference: https://www.iana.org/assignments/dns-parameters/

## DNS CLASSes
| Value | Name | Description |
|-------|------|-------------|
| 1 | IN | Internet (standard) |
| 3 | CH | Chaos (version.bind queries) |
| 4 | HS | Hesiod |
| 254 | NONE | Used in prerequisites (RFC 2136) |
| 255 | ANY | Wildcard match any class |

## DNS Header Flags
| Bit | Name | Description |
|-----|------|-------------|
| QR | Query/Response | 0=query, 1=response |
| AA | Authoritative Answer | Server is authority for zone |
| TC | Truncation | Response truncated (retry TCP) |
| RD | Recursion Desired | Client wants recursive resolution |
| RA | Recursion Available | Server supports recursion |
| AD | Authentic Data | DNSSEC validated (RFC 4035) |
| CD | Checking Disabled | Disable DNSSEC validation |

## DNS OpCodes
| Code | Name | Description |
|------|------|-------------|
| 0 | Query | Standard query |
| 1 | IQuery | Inverse query (obsolete) |
| 2 | Status | Server status request |
| 4 | Notify | Zone change notification (RFC 1996) |
| 5 | Update | Dynamic update (RFC 2136) |
| 6 | DSO | DNS Stateful Operations (RFC 8490) |

## DNS RCODEs (Response Codes)
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

## Resource Record (RR) TYPEs

### Address & Basic Records
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

### DNSSEC Records
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

### Security & Authentication
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

### Service Binding (RFC 9460)
| Type | Name | Description |
|------|------|-------------|
| 64 | SVCB | General service binding |
| 65 | HTTPS | HTTPS service binding |

### Resolver & Delegation (Emerging)
| Type | Name | Description |
|------|------|-------------|
| 261 | RESINFO | Resolver information (RFC 9606) |
| TBD | DELEG | Extensible delegation (draft-ietf-dnsop-deleg) |

### Zone Management
| Type | Name | Description |
|------|------|-------------|
| 41 | OPT | EDNS pseudo-record |
| 62 | CSYNC | Child-to-parent sync (RFC 7477) |
| 63 | ZONEMD | Zone message digest (RFC 8976) |
| 251 | IXFR | Incremental zone transfer |
| 252 | AXFR | Full zone transfer |
| 255 | * (ANY) | Request all records |

### Obsolete/Experimental
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

## EDNS Option Codes
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

## Extended DNS Error (EDE) Codes (RFC 8914)
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

## DNSSEC Algorithm Numbers
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

## DS Digest Types
| Type | Algorithm | Status |
|------|-----------|--------|
| 1 | SHA-1 | **Deprecated** (validation only) |
| 2 | SHA-256 | **Recommended** |
| 4 | SHA-384 | Optional |
