# DNS Protocol RFCs

When detailed RFC information is needed, fetch the full text:
```
WebFetch: https://www.rfc-editor.org/rfc/rfc{NUMBER}.txt
```

For HTML with better formatting:
```
WebFetch: https://datatracker.ietf.org/doc/html/rfc{NUMBER}
```

## Foundational RFCs
| RFC | Title | Summary |
|-----|-------|---------|
| 1034 | Domain Names - Concepts and Facilities | Core DNS architecture and concepts |
| 1035 | Domain Names - Implementation and Specification | Wire format, message structure, master file format |
| 2136 | Dynamic Updates in DNS | UPDATE opcode for dynamic zone modifications |
| 6891 | Extension Mechanisms for DNS (EDNS0) | OPT pseudo-RR, larger UDP, flags |
| 8499 | DNS Terminology | Authoritative definitions (supersedes 7719) |
| 9499 | DNS Terminology | Latest terminology updates |

## DNSSEC Core
| RFC | Title | Summary |
|-----|-------|---------|
| 4033 | DNS Security Introduction and Requirements | DNSSEC overview and threat model |
| 4034 | Resource Records for DNSSEC | DNSKEY, RRSIG, NSEC, DS record formats |
| 4035 | Protocol Modifications for DNSSEC | Resolver and server behavior changes |
| 9364 | DNS Security Extensions (DNSSEC) | Consolidated DNSSEC specification |

## DNSSEC Operations
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

## DNS Transport
| RFC | Title | Summary |
|-----|-------|---------|
| 7766 | DNS Transport over TCP | TCP as first-class transport |
| 7828 | edns-tcp-keepalive Option | Persistent TCP connections |
| 7858 | DNS over TLS (DoT) | Encrypted DNS on port 853 |
| 8484 | DNS over HTTPS (DoH) | Encrypted DNS via HTTPS |
| 8490 | DNS Stateful Operations | DSO for persistent connections |
| 9715 | IP Fragmentation Avoidance | Path MTU and truncation handling |

## DNS Cookies & Security
| RFC | Title | Summary |
|-----|-------|---------|
| 7873 | DNS Cookies | Client/server cookies against spoofing |
| 8945 | TSIG Authentication | Shared secret for zone transfers/updates |
| 9018 | Interoperable DNS Server Cookies | Server cookie algorithm standardization |

## Record Types & Extensions
| RFC | Title | Summary |
|-----|-------|---------|
| 8552 | Underscored Naming Conventions | _prefix scoping rules |
| 8914 | Extended DNS Errors | EDE codes for detailed error info |
| 9460 | SVCB and HTTPS Records | Service binding, HTTPS record type |
| 9567 | DNS Error Reporting | Agent-based error reporting |

## Resolver Operations
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

## Authoritative Server Operations
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

## Special-Use Domains
| RFC | Title | Summary |
|-----|-------|---------|
| 6761 | Special-Use Domain Names | .localhost, .invalid, .test, etc. |
| 7686 | The .onion Domain | Tor hidden services |
| 9476 | The .alt Domain | Non-DNS name resolution |

## IPv6 & Reverse DNS
| RFC | Title | Summary |
|-----|-------|---------|
| 3596 | AAAA Record for IPv6 | IPv6 address records |
| 4472 | IPv6 DNS Operational Considerations | Dual-stack issues |
| 8501 | Reverse DNS in IPv6 for ISPs | ip6.arpa delegation strategies |

## Troubleshooting & Diagnostics
| RFC | Title | Summary |
|-----|-------|---------|
| 4697 | Observed DNS Resolution Misbehavior | Common resolver bugs |
| 8906 | DNS Servers Failure to Communicate | FLAG day issues, EDNS failures |

## Zone Management
| RFC | Title | Summary |
|-----|-------|---------|
| 1995 | Incremental Zone Transfer (IXFR) | Delta transfers |
| 5936 | DNS Zone Transfer Protocol (AXFR) | Full zone transfer |
| 7477 | Child-to-Parent Synchronization | CSYNC record for NS/glue sync |

## Privacy & Encrypted DNS
| RFC | Title | Summary |
|-----|-------|---------|
| 9250 | DNS over Dedicated QUIC | DoQ specification |
| 9230 | Oblivious DNS over HTTPS | ODoH for query privacy |
| 9462 | Discovery of Designated Resolvers | DDR for encrypted upgrade |
| 9463 | DHCP and RA Options for DDR | Network-based DDR discovery |
| 9464 | Internet X.509 PKI: ECH | ECH certificate requirements |

## Operations & Security
| RFC | Title | Summary |
|-----|-------|---------|
| 5358 | Preventing Reflector Attacks | BCP38 for DNS |
| 7706 | Decreasing Access Time to Root | Local root copies |
| 8310 | Usage Profiles for DNS over TLS | DoT deployment guidance |
| 8906 | A Common Operational Problem | DNS failure patterns |
| 8932 | Recommendations for DNS Privacy | Client privacy guidance |
| 9076 | DNS Privacy Considerations | Privacy threat model |

## Service Discovery
| RFC | Title | Summary |
|-----|-------|---------|
| 6762 | Multicast DNS | mDNS specification |
| 6763 | DNS-Based Service Discovery | DNS-SD specification |
| 8882 | DNS-SD Privacy Extensions | Private DNS-SD |
