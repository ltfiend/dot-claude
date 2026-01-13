#!/bin/bash
# email-auth-audit.sh - Audit email authentication records
# Usage: ./email-auth-audit.sh domain.com

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
