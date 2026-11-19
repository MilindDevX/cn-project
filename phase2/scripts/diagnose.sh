#!/bin/sh
# Check the service one layer at a time, from DNS up to the application.
# The first failing layer is where to look.
# Usage: phase2/scripts/diagnose.sh MILIND_IP ISHA_IP
set -u
[ $# -eq 2 ] || { echo "usage: $0 MILIND_IP ISHA_IP" >&2; exit 2; }
milind=$1 isha=$2 name=app.team18.test
ok() { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; }

echo "1. DNS"
for server in "$milind" "$isha"; do
  answer=$(dig @"$server" "$name" A +short +time=2 +tries=1 2>/dev/null | head -1)
  case $answer in
    [0-9]*) ok "$server answers $name -> $answer" ;;
    *) bad "$server gives no answer for $name" ;;
  esac
done
# dscacheutil can hang when every configured server is down, so give it 5 seconds.
tmp=$(mktemp)
dscacheutil -q host -a name "$name" > "$tmp" 2>/dev/null & pid=$!
( sleep 5; kill "$pid" 2>/dev/null ) & watcher=$!
wait "$pid" 2>/dev/null; { kill "$watcher"; wait "$watcher"; } 2>/dev/null
system=$(awk '/ip_address/ {print $2; exit}' "$tmp"); rm -f "$tmp"
if [ -n "$system" ]; then ok "system resolver (with its cache) -> $system"; else bad "system resolver has no answer; check /etc/resolver/team18.test"; fi
edge=${system:-$isha}

echo "2. IP reachability to the edge ($edge)"
if ping -c 1 -t 2 "$edge" >/dev/null 2>&1; then ok "ping $edge"; else bad "no ping reply from $edge (host down, wrong address, or ICMP blocked)"; fi

echo "3. TCP"
edge_tcp=no
if nc -z -G 3 "$edge" 443 2>/dev/null; then ok "TCP connect $edge:443"; edge_tcp=yes; else bad "TCP connect $edge:443 failed (edge not listening, or blocked)"; fi
for backend in "$milind:3001" "$isha:3002"; do
  if nc -z -G 3 "${backend%:*}" "${backend#*:}" 2>/dev/null; then
    ok "TCP connect $backend (direct; refused or timing out is expected while backend firewall rules are on)"
  else
    bad "TCP connect $backend (backend down, or isolated by its firewall)"
  fi
done

echo "4. TLS"
if [ "$edge_tcp" = no ]; then
  bad "skipped: no TCP connection to $edge:443"
else
tls=$(echo | openssl s_client -connect "$edge:443" -servername "$name" -verify_return_error 2>&1)
if echo "$tls" | grep -q 'Verify return code: 0'; then
  ok "certificate for $name verified ($(echo "$tls" | awk -F': ' '/^ *Protocol/ {print $2; exit}'))"
else
  bad "TLS failed: $(echo "$tls" | grep -m1 -iE 'verify error|errno|refused|alert' || echo 'see openssl s_client output')"
fi
fi

echo "5. HTTP"
headers=$(curl -sS --max-time 8 -D - -o /dev/null "https://$name/api/status" 2>&1 | tr -d '\r')
status=$(echo "$headers" | awk '/^HTTP/ {print $2; exit}')
backend=$(echo "$headers" | awk -F': ' 'tolower($1)=="x-backend" {print $2}')
edge_name=$(echo "$headers" | awk -F': ' 'tolower($1)=="x-edge" {print $2}')
case $status in
  200) ok "GET /api/status -> 200 from backend ${backend:-?} via ${edge_name:-?} edge" ;;
  502|503|504) bad "GET /api/status -> $status: the edge works but no backend answered" ;;
  "") bad "no HTTP response: $(echo "$headers" | head -1)" ;;
  *) bad "GET /api/status -> $status" ;;
esac
