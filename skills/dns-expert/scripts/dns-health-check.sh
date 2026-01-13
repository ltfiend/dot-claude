#!/bin/bash
# dns-health-check.sh - Check for common DNS misconfigurations
# Usage: ./dns-health-check.sh domain.com

DOMAIN="${1:?Usage: $0 domain.com}"

echo "=== DNS Health Check: $DOMAIN ==="
echo

# Check for lame delegation
echo "--- Checking Nameserver Health ---"
for ns in $(dig +short "$DOMAIN" NS); do
  echo -n "$ns: "
  if timeout 5 dig +short "@$ns" "$DOMAIN" SOA >/dev/null 2>&1; then
    echo "✓ OK"
  else
    echo "✗ LAME - not authoritative"
  fi
done

# Check SOA serial consistency
echo -e "\n--- Checking SOA Serial Consistency ---"
serials=""
for ns in $(dig +short "$DOMAIN" NS); do
  serial=$(dig +short "@$ns" "$DOMAIN" SOA 2>/dev/null | awk '{print $3}')
  echo "$ns: $serial"
  serials="$serials$serial\n"
done
unique_serials=$(echo -e "$serials" | sort -u | grep -v '^$' | wc -l)
if [ "$unique_serials" -eq 1 ]; then
  echo "✓ All nameservers have consistent serial"
else
  echo "⚠ Serial mismatch detected!"
fi

# Check for glue records if needed
echo -e "\n--- Checking Glue Records ---"
for ns in $(dig +short "$DOMAIN" NS); do
  if echo "$ns" | grep -q "$DOMAIN"; then
    echo "$ns is in-bailiwick, checking glue..."
    glue=$(dig +additional "$DOMAIN" NS 2>/dev/null | grep -A20 "ADDITIONAL" | grep "$ns")
    if [ -n "$glue" ]; then
      echo "  ✓ Glue present"
    else
      echo "  ⚠ Missing glue record!"
    fi
  fi
done

# Check for exposed internal records
echo -e "\n--- Checking for Exposed Internal Records ---"
found_internal=0
for name in localhost internal private intranet corp vpn dc dc1 ad exchange; do
  result=$(dig +short "$name.$DOMAIN" A 2>/dev/null)
  if [ -n "$result" ]; then
    echo "⚠ Found: $name.$DOMAIN -> $result"
    echo "$result" | grep -qE "^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)" && \
      echo "  ⚠ RFC1918 private IP exposed!"
    found_internal=1
  fi
done
[ $found_internal -eq 0 ] && echo "✓ No obvious internal records exposed"

# Check DNS server version exposure
echo -e "\n--- Checking Version Exposure ---"
for ns in $(dig +short "$DOMAIN" NS | head -2); do
  version=$(dig +short "@$ns" version.bind TXT CH 2>/dev/null | tr -d '"')
  if [ -n "$version" ]; then
    echo "⚠ $ns exposes version: $version"
  else
    echo "✓ $ns version hidden"
  fi
done

echo -e "\n=== Health Check Complete ==="
