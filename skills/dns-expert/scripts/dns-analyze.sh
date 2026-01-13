#!/bin/bash
# dns-analyze.sh - Comprehensive DNS zone analysis
# Usage: ./dns-analyze.sh domain.com

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
