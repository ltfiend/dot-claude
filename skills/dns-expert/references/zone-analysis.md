# DNS Zone Analysis & Reconnaissance

## Complete Zone Analysis Workflow

When analyzing an unknown domain, follow this systematic approach:

```bash
#!/bin/bash
# dns-analyze.sh - Comprehensive DNS zone analysis
DOMAIN="${1:?Usage: $0 domain.com}"

echo "=== DNS Analysis: $DOMAIN ==="
echo

# 1. Basic records
echo "--- Basic Records ---"
for type in A AAAA NS MX TXT SOA CAA; do
  echo "[$type]"
  dig +short "$DOMAIN" "$type" 2>/dev/null
done

# 2. DNSSEC status
echo -e "\n--- DNSSEC ---"
dig +short "$DOMAIN" DNSKEY && echo "DNSSEC: Enabled" || echo "DNSSEC: Disabled"
dig +short "$DOMAIN" DS

# 3. Email authentication
echo -e "\n--- Email Authentication ---"
echo "[SPF]"
dig +short "$DOMAIN" TXT | grep -i spf
echo "[DMARC]"
dig +short "_dmarc.$DOMAIN" TXT
echo "[MTA-STS]"
dig +short "_mta-sts.$DOMAIN" TXT
echo "[BIMI]"
dig +short "default._bimi.$DOMAIN" TXT

# 4. Service discovery
echo -e "\n--- Service Records ---"
for svc in _autodiscover._tcp _sip._tcp _xmpp-server._tcp _caldav._tcp; do
  result=$(dig +short "$svc.$DOMAIN" SRV 2>/dev/null)
  [ -n "$result" ] && echo "$svc: $result"
done

# 5. Modern records
echo -e "\n--- Modern Records ---"
echo "[HTTPS/SVCB]"
dig +short "$DOMAIN" HTTPS
echo "[TLSA]"
dig +short "_443._tcp.$DOMAIN" TLSA
```

## Zone Enumeration via NSEC Walking

NSEC records form a linked list of all names in a zone, enabling complete enumeration:

```bash
# Manual NSEC walk
walk_nsec() {
  local domain="$1"
  local current="$domain"
  local count=0

  echo "Walking NSEC chain for $domain"
  while true; do
    next=$(dig +short "$current" NSEC 2>/dev/null | awk '{print $1}')

    # Check for end of chain or wrap
    if [ -z "$next" ] || [ "$next" = "${domain}." ]; then
      echo "Chain complete: $count entries"
      break
    fi

    # Get record types at this name
    types=$(dig +short "$current" NSEC | cut -d' ' -f2-)
    echo "$current: $types"

    current="$next"
    ((count++))

    # Safety limit
    [ $count -gt 1000 ] && echo "Limit reached" && break
  done
}

walk_nsec example.com
```

```bash
# Using ldns-walk (faster)
ldns-walk example.com

# Using nsec3walker for NSEC3 zones
nsec3walker --zone example.com --nameserver ns1.example.com
```

### NSEC vs NSEC3 Detection

```bash
# Check which denial-of-existence is used
check_nsec_type() {
  local domain="$1"

  # Query for non-existent name to trigger denial
  result=$(dig +dnssec "nonexistent-xyz123.$domain" A 2>/dev/null)

  if echo "$result" | grep -q "NSEC3"; then
    echo "$domain uses NSEC3 (zone enumeration resistant)"
    # Extract NSEC3 parameters
    dig +short "$domain" NSEC3PARAM
  elif echo "$result" | grep -q "NSEC[^3]"; then
    echo "$domain uses NSEC (zone enumerable)"
  else
    echo "$domain: No DNSSEC or query failed"
  fi
}
```

## Email Authentication Audit

### Complete Email Security Check

```bash
#!/bin/bash
# email-auth-audit.sh - Audit email authentication records
DOMAIN="${1:?Usage: $0 domain.com}"

echo "=== Email Authentication Audit: $DOMAIN ==="

# SPF Analysis
echo -e "\n[SPF Record]"
spf=$(dig +short "$DOMAIN" TXT | grep -i "v=spf1" | tr -d '"')
if [ -n "$spf" ]; then
  echo "$spf"

  # Check for common issues
  echo "$spf" | grep -q "+all" && echo "⚠ WARNING: +all allows any sender"
  echo "$spf" | grep -q "~all" && echo "⚠ NOTICE: ~all is soft fail (consider -all)"
  echo "$spf" | grep -q "\-all" && echo "✓ Hard fail policy (-all)"
  echo "$spf" | grep -q "redirect=" && echo "ℹ Uses redirect mechanism"

  # Count DNS lookups (max 10 allowed)
  includes=$(echo "$spf" | grep -o "include:" | wc -l)
  echo "ℹ Include count: $includes (max 10 lookups total)"
else
  echo "✗ No SPF record found"
fi

# DKIM Selectors (common ones)
echo -e "\n[DKIM Records]"
for selector in default selector1 selector2 google k1 s1 s2 mail dkim; do
  dkim=$(dig +short "${selector}._domainkey.$DOMAIN" TXT 2>/dev/null | head -1)
  if [ -n "$dkim" ]; then
    echo "✓ $selector._domainkey: Found"
    # Check key size (rough estimate from p= length)
    plen=$(echo "$dkim" | grep -o 'p=[^;]*' | wc -c)
    if [ "$plen" -lt 300 ]; then
      echo "  ⚠ Key appears to be 1024-bit or less (upgrade to 2048)"
    fi
  fi
done

# DMARC Analysis
echo -e "\n[DMARC Record]"
dmarc=$(dig +short "_dmarc.$DOMAIN" TXT | tr -d '"')
if [ -n "$dmarc" ]; then
  echo "$dmarc"

  # Parse policy
  policy=$(echo "$dmarc" | grep -o 'p=[^;]*' | cut -d= -f2)
  case "$policy" in
    none)    echo "⚠ Policy: none (monitoring only)" ;;
    quarantine) echo "✓ Policy: quarantine" ;;
    reject)  echo "✓ Policy: reject (strongest)" ;;
  esac

  # Check for rua (aggregate reports)
  echo "$dmarc" | grep -q "rua=" && echo "✓ Aggregate reporting enabled"
  echo "$dmarc" | grep -q "ruf=" && echo "✓ Forensic reporting enabled"

  # Check subdomain policy
  sp=$(echo "$dmarc" | grep -o 'sp=[^;]*' | cut -d= -f2)
  [ -n "$sp" ] && echo "ℹ Subdomain policy: $sp"
else
  echo "✗ No DMARC record found"
fi

# MTA-STS
echo -e "\n[MTA-STS]"
mtasts=$(dig +short "_mta-sts.$DOMAIN" TXT | tr -d '"')
if [ -n "$mtasts" ]; then
  echo "✓ MTA-STS enabled: $mtasts"
else
  echo "✗ No MTA-STS record"
fi

# TLS-RPT (TLS Reporting)
echo -e "\n[TLS-RPT]"
tlsrpt=$(dig +short "_smtp._tls.$DOMAIN" TXT | tr -d '"')
if [ -n "$tlsrpt" ]; then
  echo "✓ TLS-RPT enabled: $tlsrpt"
else
  echo "✗ No TLS-RPT record"
fi

# BIMI
echo -e "\n[BIMI]"
bimi=$(dig +short "default._bimi.$DOMAIN" TXT | tr -d '"')
if [ -n "$bimi" ]; then
  echo "✓ BIMI enabled: $bimi"
else
  echo "ℹ No BIMI record (optional)"
fi
```

## Zone Security Checklist

Use this checklist when auditing a DNS zone:

### Authentication & Signing
- [ ] **DNSSEC enabled** - Zone is signed
- [ ] **Algorithm current** - Using ECDSA (13/14) or Ed25519 (15), not RSA-SHA1
- [ ] **DS at parent** - Delegation signer properly published
- [ ] **RRSIG not expiring** - Signatures have > 7 days validity
- [ ] **Key sizes adequate** - RSA ≥ 2048-bit, ECDSA P-256+

### Email Security
- [ ] **SPF present** - With `-all` (hard fail)
- [ ] **SPF < 10 lookups** - Avoid "too many DNS lookups" errors
- [ ] **DKIM present** - At least one selector
- [ ] **DKIM key ≥ 2048-bit** - 1024-bit is weak
- [ ] **DMARC present** - With `p=reject` or `p=quarantine`
- [ ] **DMARC reporting** - `rua=` for aggregate reports
- [ ] **MTA-STS** - Enforce TLS for inbound mail

### Certificate Security
- [ ] **CAA records** - Restrict certificate issuance
- [ ] **CAA iodef** - Violation reporting configured
- [ ] **TLSA/DANE** - Certificate pinning (if applicable)

### Zone Hygiene
- [ ] **No test records** - Remove `test`, `dev`, `tmp` entries
- [ ] **No internal IPs** - RFC1918 addresses shouldn't be public
- [ ] **No sensitive names** - Avoid exposing infrastructure names
- [ ] **NSEC3 if needed** - Prevent enumeration of sensitive zones
- [ ] **Reasonable TTLs** - Not too low (DDoS risk) or too high (agility)

### Nameserver Security
- [ ] **Multiple NS** - At least 2, preferably 3+
- [ ] **NS diversity** - Different networks/providers
- [ ] **Glue records** - Present where required
- [ ] **No open recursion** - Authoritative servers shouldn't recurse
- [ ] **Version hidden** - `version.bind` returns nothing useful

## DNS Fingerprinting

Identify DNS server software for security assessment:

```bash
# Query version via CHAOS class
dig @ns1.example.com version.bind TXT CH +short
dig @ns1.example.com version.server TXT CH +short

# Query hostname
dig @ns1.example.com hostname.bind TXT CH +short
dig @ns1.example.com id.server TXT CH +short

# NSID (if enabled)
dig +nsid @ns1.example.com example.com

# Fingerprint via behavior (fpdns)
fpdns ns1.example.com
```

### Common Version Strings

| Response | Software |
|----------|----------|
| `9.18.x` | BIND 9.18 |
| `PowerDNS Authoritative...` | PowerDNS |
| `NSD x.x.x` | NSD |
| `Knot DNS x.x.x` | Knot |
| (empty/refused) | Properly hardened |

## Common Misconfigurations

### Lame Delegation
```bash
# Check if all NS actually serve the zone
check_lame() {
  for ns in $(dig +short "$1" NS); do
    echo -n "$ns: "
    if dig +short "@$ns" "$1" SOA >/dev/null 2>&1; then
      echo "OK"
    else
      echo "LAME - not authoritative"
    fi
  done
}
```

### Inconsistent Serial Numbers
```bash
# Compare SOA serial across all nameservers
check_serials() {
  for ns in $(dig +short "$1" NS); do
    serial=$(dig +short "@$ns" "$1" SOA | awk '{print $3}')
    echo "$ns: $serial"
  done
}
```

### Missing Glue
```bash
# Check for glue when NS is in-bailiwick
check_glue() {
  local domain="$1"
  for ns in $(dig +short "$domain" NS); do
    if echo "$ns" | grep -q "$domain"; then
      # NS is in-bailiwick, needs glue
      glue=$(dig +additional "$domain" NS @a.gtld-servers.net | grep -A10 "ADDITIONAL" | grep "$ns")
      if [ -z "$glue" ]; then
        echo "⚠ Missing glue for $ns"
      fi
    fi
  done
}
```

### Exposed Internal Records
```bash
# Scan for common internal hostnames
check_internal() {
  local domain="$1"
  for name in localhost internal private intranet corp vpn \
              dc dc1 ad ad1 exchange mail01 db01 web01 \
              dev test staging uat prod; do
    result=$(dig +short "$name.$domain" A 2>/dev/null)
    if [ -n "$result" ]; then
      echo "Found: $name.$domain -> $result"
      # Flag RFC1918 addresses
      echo "$result" | grep -qE "^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)" && \
        echo "  ⚠ RFC1918 private IP exposed"
    fi
  done
}
```

## Delegation Analysis

```bash
# Full delegation chain analysis
analyze_delegation() {
  local domain="$1"

  echo "=== Delegation Analysis: $domain ==="

  # Get parent zone
  parent=$(echo "$domain" | cut -d. -f2-)
  echo -e "\nParent zone: $parent"

  # Get NS from parent (authoritative view)
  echo -e "\nNS records at parent:"
  dig +norecurse "$domain" NS @$(dig +short "$parent" NS | head -1) | grep -A10 "AUTHORITY"

  # Get NS from zone itself
  echo -e "\nNS records from zone:"
  dig +short "$domain" NS

  # Check DS at parent
  echo -e "\nDS record at parent:"
  dig +short "$domain" DS @$(dig +short "$parent" NS | head -1)

  # Compare DNSKEY
  echo -e "\nDNSKEY in zone:"
  dig +short "$domain" DNSKEY | head -2
}
```

## Comprehensive Zone Report

```bash
#!/bin/bash
# zone-report.sh - Generate full DNS zone report
DOMAIN="${1:?Usage: $0 domain.com}"
REPORT="dns-report-${DOMAIN}-$(date +%Y%m%d).txt"

{
  echo "DNS Zone Report: $DOMAIN"
  echo "Generated: $(date)"
  echo "=============================================="

  echo -e "\n## BASIC INFO"
  echo "Registrar: $(whois "$DOMAIN" 2>/dev/null | grep -i registrar | head -1)"
  echo "Created: $(whois "$DOMAIN" 2>/dev/null | grep -i creat | head -1)"

  echo -e "\n## NAMESERVERS"
  dig +short "$DOMAIN" NS | while read ns; do
    ip=$(dig +short "$ns" A | head -1)
    echo "  $ns ($ip)"
  done

  echo -e "\n## SOA"
  dig +short "$DOMAIN" SOA

  echo -e "\n## DNSSEC"
  if dig +short "$DOMAIN" DNSKEY | head -1 | grep -q .; then
    echo "Status: Enabled"
    echo "Algorithm: $(dig +short "$DOMAIN" DNSKEY | head -1 | awk '{print $3}')"
    echo "DS: $(dig +short "$DOMAIN" DS | head -1)"
  else
    echo "Status: Disabled"
  fi

  echo -e "\n## EMAIL AUTHENTICATION"
  echo "SPF: $(dig +short "$DOMAIN" TXT | grep spf | head -1)"
  echo "DMARC: $(dig +short "_dmarc.$DOMAIN" TXT | head -1)"

  echo -e "\n## SECURITY RECORDS"
  echo "CAA: $(dig +short "$DOMAIN" CAA)"
  echo "HTTPS: $(dig +short "$DOMAIN" HTTPS)"

  echo -e "\n## RECORD COUNTS"
  for type in A AAAA MX TXT NS; do
    count=$(dig +short "$DOMAIN" "$type" 2>/dev/null | wc -l)
    echo "  $type: $count"
  done

} | tee "$REPORT"

echo -e "\nReport saved to: $REPORT"
```
