#!/bin/bash
# zone-report.sh - Generate full DNS zone report
# Usage: ./zone-report.sh domain.com

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
