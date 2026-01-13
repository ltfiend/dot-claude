#!/bin/bash
# dnssec-check.sh - Check DNSSEC validation status
# Usage: ./dnssec-check.sh domain.com [resolver]
# Exit codes: 0=valid, 1=no DNSSEC, 2=validation failed

DOMAIN="${1:?Usage: $0 domain.com [resolver]}"
RESOLVER="${2:-8.8.8.8}"

echo "=== DNSSEC Check: $DOMAIN ==="
echo "Resolver: $RESOLVER"
echo

# Check if domain has DNSSEC
echo "--- Checking DNSKEY ---"
dnskey=$(dig +short "@$RESOLVER" "$DOMAIN" DNSKEY 2>/dev/null)
if [ -z "$dnskey" ]; then
  echo "✗ No DNSKEY found - domain is not signed"
  exit 1
fi
echo "✓ DNSKEY found"

# Check DS at parent
echo -e "\n--- Checking DS at parent ---"
ds=$(dig +short "@$RESOLVER" "$DOMAIN" DS 2>/dev/null)
if [ -z "$ds" ]; then
  echo "⚠ No DS record at parent - chain incomplete"
else
  echo "✓ DS record found: $ds"
fi

# Check RRSIG
echo -e "\n--- Checking RRSIG ---"
rrsig=$(dig +dnssec "@$RESOLVER" "$DOMAIN" A 2>/dev/null | grep RRSIG)
if [ -z "$rrsig" ]; then
  echo "✗ No RRSIG found"
  exit 2
fi
echo "✓ RRSIG found"

# Validation test using CD flag comparison
echo -e "\n--- Validation Test ---"
with_validation=$(dig +dnssec "@$RESOLVER" "$DOMAIN" A 2>/dev/null | grep -c "ad")
without_validation=$(dig +cd "@$RESOLVER" "$DOMAIN" A 2>/dev/null | grep -c "ANSWER")

if [ "$with_validation" -gt 0 ]; then
  echo "✓ DNSSEC validation successful (AD flag set)"
  exit 0
elif [ "$without_validation" -gt 0 ]; then
  echo "⚠ Response received with CD flag but validation may have issues"
  exit 2
else
  echo "✗ DNSSEC validation failed"
  exit 2
fi
