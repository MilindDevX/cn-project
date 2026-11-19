#!/bin/sh
# Render the Phase 2 configs for today's addresses into phase2/build/.
# Usage: phase2/scripts/render.sh MILIND_IP ISHA_IP [EDGE_IP]
# EDGE_IP is the address app.team18.test points to (default: ISHA_IP).
set -eu
[ $# -ge 2 ] || { echo "usage: $0 MILIND_IP ISHA_IP [EDGE_IP]" >&2; exit 2; }
milind=$1 isha=$2 edge=${3:-$2}
for ip in "$milind" "$isha" "$edge"; do
  echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || { echo "not an IPv4 address: $ip" >&2; exit 2; }
done
here=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$here/build"
for f in "$here"/templates/*; do
  sed -e "s/{{MILIND_IP}}/$milind/g" -e "s/{{ISHA_IP}}/$isha/g" -e "s/{{EDGE_IP}}/$edge/g" \
    "$f" > "$here/build/$(basename "$f")"
done
echo "Rendered to $here/build (Milind $milind, Isha $isha, record -> $edge)"
