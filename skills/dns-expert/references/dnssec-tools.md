# DNSSEC Visualization & Analysis Tools

## dnsviz

DNSViz is the gold standard for DNSSEC visualization and debugging. It traces the DNSSEC chain of trust and identifies validation issues.

### Installation
```bash
# Ubuntu/Debian
sudo apt install dnsviz

# macOS
brew install dnsviz

# pip (cross-platform)
pip install dnsviz

# Dependencies for graphing
sudo apt install graphviz  # or: brew install graphviz
```

### Core Commands

```bash
# Probe domain - collect DNSSEC data from authoritative servers
dnsviz probe example.com -o example.json

# Probe with specific resolver
dnsviz probe example.com -r 8.8.8.8 -o example.json

# Probe multiple domains
dnsviz probe example.com example.org -o results.json

# Recursive probe (follow all delegations from root)
dnsviz probe -A example.com -o example.json
```

### Visualization & Analysis

```bash
# Generate SVG graph of DNSSEC chain
dnsviz graph -Tsvg -o dnssec-chain.svg < example.json

# Generate PNG
dnsviz graph -Tpng -o dnssec-chain.png < example.json

# Generate HTML (interactive)
dnsviz graph -Thtml -o dnssec-chain.html < example.json

# Analyze and report errors (grok)
dnsviz grok < example.json

# Print detailed textual analysis
dnsviz print < example.json

# Print only errors and warnings
dnsviz print -l error -l warning < example.json
```

### Common Workflows

```bash
# Full DNSSEC audit of a domain
dnsviz probe example.com -o audit.json && \
dnsviz grok < audit.json && \
dnsviz graph -Tsvg -o audit.svg < audit.json

# Check if DNSSEC is properly configured
dnsviz probe example.com | dnsviz grok
# Exit code 0 = valid, non-zero = errors

# Compare DNSSEC state over time
dnsviz probe example.com -o before.json
# ... make changes ...
dnsviz probe example.com -o after.json
diff <(dnsviz print < before.json) <(dnsviz print < after.json)

# Validate specific DS record
dnsviz probe example.com | dnsviz print | grep -A5 "DS"
```

### Interpreting dnsviz Output

| Symbol | Meaning |
|--------|---------|
| ✓ (green) | Valid DNSSEC signature |
| ✗ (red) | Invalid/missing signature |
| ⚠ (yellow) | Warning (expiring soon, weak algorithm) |
| → | Delegation or CNAME chain |
| DS → DNSKEY | Trust chain link |

### Common dnsviz Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `No DNSKEY matching DS` | DS at parent doesn't match any DNSKEY | Update DS record at registrar |
| `RRSIG expired` | Signature past validity | Re-sign zone, check signing automation |
| `No valid RRSIGs` | Missing or invalid signatures | Verify zone signing is active |
| `Algorithm not supported` | Using deprecated algorithm | Migrate to ECDSA (13) or Ed25519 (15) |
| `NSEC3 iterations too high` | Iterations > 100 | Lower iterations per RFC 9276 |

## Online DNSSEC Analyzers

When local tools aren't available, use these web services:

| Service | URL | Features |
|---------|-----|----------|
| DNSViz | https://dnsviz.net | Full visualization, historical data |
| Verisign Analyzer | https://dnssec-analyzer.verisignlabs.com | Chain validation, clear errors |
| DNSSEC Debugger | https://dnssec-debugger.verisignlabs.com | Interactive debugging |
| Zonemaster | https://zonemaster.net | Comprehensive DNS/DNSSEC tests |
| IntoDNS | https://intodns.com | DNS health check (basic DNSSEC) |
| DNScheck.tools | https://dnscheck.tools | Multi-location testing |

### Using DNSViz Web API
```bash
# Fetch analysis via API (JSON)
curl -s "https://dnsviz.net/d/example.com/dnssec/" | jq .

# Get SVG directly
curl -s "https://dnsviz.net/d/example.com/graph.svg" -o example.svg
```

## ldns Tools

The ldns library provides powerful DNSSEC utilities:

```bash
# Install
sudo apt install ldnsutils  # Debian/Ubuntu
brew install ldns           # macOS

# Generate DS record from DNSKEY
ldns-key2ds -n -2 Kexample.com.+013+12345.key

# Verify DNSSEC chain
ldns-verify-zone example.com.zone

# Create DANE/TLSA record
ldns-dane create www.example.com 443 3 1 1

# Walk NSEC chain (zone enumeration)
ldns-walk example.com

# Sign a zone
ldns-signzone -n -o example.com example.com.zone Kexample.com.+013+12345.private

# Read DNSKEY and output DS
ldns-read-zone example.com.zone | grep DNSKEY | ldns-key2ds -n -2 /dev/stdin
```

## BIND DNSSEC Tools

```bash
# Generate DNSSEC keys
dnssec-keygen -a ECDSAP256SHA256 -b 256 -n ZONE example.com  # ZSK
dnssec-keygen -a ECDSAP256SHA256 -b 256 -n ZONE -f KSK example.com  # KSK

# Sign zone
dnssec-signzone -o example.com -N INCREMENT -k Kexample.com.+013+*.key \
  example.com.zone Kexample.com.+013+*.private

# Generate DS from DNSKEY file
dnssec-dsfromkey Kexample.com.+013+12345.key

# Generate DS from DNSKEY in zone (piped)
dig example.com DNSKEY | dnssec-dsfromkey -f - example.com

# Verify zone signatures
dnssec-verify -o example.com example.com.zone.signed

# Check key timing
dnssec-settime -p all Kexample.com.+013+12345.key

# Import existing key
dnssec-importkey -f Kexample.com.+013+12345.key
```

## Knot DNS Tools

```bash
# Install
sudo apt install knot-dnsutils

# Interactive DNSSEC debugging
kdig +dnssec +multi example.com

# Trace with DNSSEC validation
kdig +trace +dnssec example.com

# Check DANE/TLSA
kdig _443._tcp.example.com TLSA

# DNS over QUIC
kdig +quic @dns.adguard-dns.com example.com

# Zone signing with keymgr
keymgr example.com. generate algorithm=ECDSAP256SHA256 ksk=true
keymgr example.com. generate algorithm=ECDSAP256SHA256
keymgr example.com. list
```

## delv (DNSSEC Lookup & Validation)

`delv` is BIND's DNSSEC-aware replacement for dig:

```bash
# Basic DNSSEC validation
delv example.com

# Validate against specific trust anchor
delv -a /etc/bind/root.key example.com

# Show detailed validation chain
delv +vtrace example.com

# Check specific record type
delv example.com MX

# Validate using specific resolver
delv @8.8.8.8 example.com

# Show reason for validation failure
delv +rtrace example.com
```

### delv Output Interpretation

```
; fully validated        # DNSSEC chain verified successfully
; unsigned answer        # Domain not signed (no DNSSEC)
; negative response, unsigned  # NXDOMAIN, no DNSSEC
; broken trust chain     # DNSSEC validation failed
```

## drill (ldns-based dig Alternative)

```bash
# Install
sudo apt install ldnsutils  # includes drill

# DNSSEC trace
drill -DT example.com

# Chase DNSSEC signatures
drill -DS example.com

# Show trust chain
drill -S example.com

# Query with DNSSEC
drill -D example.com DNSKEY
```

## Automated DNSSEC Monitoring

### Nagios/Icinga Check
```bash
#!/bin/bash
# check_dnssec.sh - Nagios plugin for DNSSEC monitoring
DOMAIN=$1
OUTPUT=$(dnsviz probe "$DOMAIN" 2>&1 | dnsviz grok 2>&1)
EXITCODE=$?

if [ $EXITCODE -eq 0 ]; then
    echo "DNSSEC OK - $DOMAIN chain valid"
    exit 0
else
    echo "DNSSEC CRITICAL - $DOMAIN: $OUTPUT"
    exit 2
fi
```

### Prometheus/Alertmanager
```yaml
# prometheus alert rule
groups:
  - name: dnssec
    rules:
      - alert: DNSSECValidationFailure
        expr: dnssec_valid{domain="example.com"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "DNSSEC validation failed for {{ $labels.domain }}"
```

### Cron-based Monitoring Script
```bash
#!/bin/bash
# dnssec-monitor.sh - Check DNSSEC and alert on failure
DOMAINS="example.com example.org"
ALERT_EMAIL="admin@example.com"

for domain in $DOMAINS; do
    if ! dnsviz probe "$domain" 2>/dev/null | dnsviz grok >/dev/null 2>&1; then
        echo "DNSSEC validation failed for $domain at $(date)" | \
            mail -s "DNSSEC Alert: $domain" "$ALERT_EMAIL"
    fi
done
```

## DNSSEC Testing Domains

Use these domains to test your tools and resolver DNSSEC validation:

| Domain | Expected Result | Purpose |
|--------|-----------------|---------|
| dnssec-failed.org | SERVFAIL | Deliberately broken DNSSEC |
| www.dnssec-failed.org | SERVFAIL | Broken signature |
| sigok.verteiltesysteme.net | Valid | Known-good DNSSEC |
| sigfail.verteiltesysteme.net | SERVFAIL | Expired signature |
| dnssec.vs.uni-due.de | Valid | Test suite |
| rootcanary.net | Valid | Root KSK monitoring |

```bash
# Test resolver DNSSEC validation
dig @your-resolver dnssec-failed.org A
# Should return SERVFAIL if validating

dig @your-resolver +cd dnssec-failed.org A
# Returns answer (CD=Checking Disabled bypasses validation)
```
