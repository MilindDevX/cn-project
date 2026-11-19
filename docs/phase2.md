# Phase 2: resilience, isolation and recovery

Phase 2 extends the Phase 1 network on the same two Macs. Nothing is rebuilt.

| Change | Mac | Extension |
| --- | --- | --- |
| Backup dnsmasq with the same records | Isha's | A |
| Both DNS servers listed in each client's resolver | Both | A |
| 30-second TTL; the record lives in a hosts file that reloads without a restart | Both DNS servers | B |
| pf firewall rules: only the edge reaches the backend ports | Both | C |
| Faster failure detection: request timeouts and passive health checks | Isha's (edge) | D |
| Standby Caddy edge with the same site configuration | Milind's | E |
| A layer-by-layer diagnosis script | Either | F |

## Addresses

Both Macs get their addresses by DHCP, so every config is a template in
[`phase2/templates/`](../phase2/templates). Render them for the day's
addresses on each Mac:

```sh
ipconfig getifaddr en0                       # on each Mac
phase2/scripts/render.sh MILIND_IP ISHA_IP   # writes phase2/build/
```

The commands below use `$MILIND` and `$ISHA` for those addresses:

```sh
MILIND=10.7.20.246 ISHA=10.7.16.207   # replace with the day's values
```

## Setup

On Milind's Mac (primary DNS, Backend A, standby edge):

```sh
sudo cp phase2/build/dnsmasq-primary.conf /opt/homebrew/etc/dnsmasq.d/team18.conf
sudo cp phase2/build/team18.hosts /opt/homebrew/etc/team18.hosts
sudo brew services restart dnsmasq
node phase1/backend/backend-a.js
```

On Isha's Mac (backup DNS, edge, Backend B):

```sh
brew install dnsmasq
sudo cp phase2/build/dnsmasq-backup.conf /opt/homebrew/etc/dnsmasq.d/team18.conf
sudo cp phase2/build/team18.hosts /opt/homebrew/etc/team18.hosts
sudo brew services restart dnsmasq
node phase1/backend/backend-b.js
cp phase2/build/Caddyfile <certificate directory>/Caddyfile
caddy start --config Caddyfile --adapter caddyfile   # from the certificate directory
```

On both Macs, list both DNS servers for the project domain:

```sh
sudo cp phase2/build/resolver-team18.test /etc/resolver/team18.test
scutil --dns | grep -A3 team18.test
```

Run the extensions in the order A, B, C, D, E. Extension C must be rolled
back before E, because the standby edge reaches Backend B over the LAN.

## A. Backup DNS resolver

```sh
dig @$MILIND app.team18.test A +short   # primary answers
dig @$ISHA app.team18.test A +short     # backup gives the same answer
```

Stop the primary on Milind's Mac, then on a client clear the local cache so
the answer cannot come from it:

```sh
sudo brew services stop dnsmasq                                     # Milind's Mac
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder       # client
dig @$MILIND app.team18.test A +time=2 +tries=1                     # no answer
dscacheutil -q host -a name app.team18.test                         # answered by the backup
curl -i https://app.team18.test/api/status                          # service still reachable
sudo brew services start dnsmasq                                    # Milind's Mac, afterwards
```

A DNS failure stops name resolution, so clients cannot find any service even
though every server is healthy. An application failure is the opposite: the
name resolves and TCP may connect, but the service returns an error or
refuses the connection.

## B. TTL and a controlled record change

Every answer for `app.team18.test` carries a 30-second TTL:

```sh
dig @$MILIND app.team18.test A +noall +answer
# app.team18.test.  30  IN  A  <edge address>
```

In one client terminal, watch what the system resolver returns:

```sh
while true; do
  printf '%s  cache: %s  server: %s\n' "$(date +%T)" \
    "$(dscacheutil -q host -a name app.team18.test | awk '/ip_address/ {print $2}')" \
    "$(dig @$MILIND app.team18.test A +short)"
  sleep 3
done
```

On the DNS servers, point the record at Milind's Mac and reload it without
restarting dnsmasq:

```sh
phase2/scripts/render.sh $MILIND $ISHA $MILIND
sudo cp phase2/build/team18.hosts /opt/homebrew/etc/team18.hosts
sudo pkill -HUP dnsmasq
```

The `server` column changes at once. The `cache` column keeps the old address
for up to 30 seconds, then follows. To skip the wait, flush the client cache:

```sh
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

Change the record back by rendering without the third argument and repeating
the copy and reload.

## C. Backend isolation with pf

The rules go into the `com.apple/team18` anchor, which the stock
`/etc/pf.conf` already evaluates, so the system file is never edited.

Save the current state, load the rules and enable pf (on each Mac, with its
own rule file):

```sh
sudo pfctl -s info | head -1                                 # pf enabled or disabled before
sudo pfctl -a com.apple/team18 -f phase2/build/backend-a.pf   # Milind's Mac
sudo pfctl -a com.apple/team18 -f phase2/build/backend-b.pf   # Isha's Mac
sudo pfctl -E                                                 # note the token it prints
sudo pfctl -a com.apple/team18 -sr                            # show the loaded rules
```

Checks:

```sh
curl -i --max-time 5 http://$MILIND:3001/api/status   # from Isha's Mac (the edge): 200
curl -i --max-time 5 http://$ISHA:3002/api/status     # from Milind's Mac: times out
curl -i https://app.team18.test/api/status            # through the edge: still A and B
```

The rules drop the packets rather than refuse them, so a blocked client sees
a timeout. A stopped backend answers with a TCP reset instead, which is how
the two cases can be told apart.

A Mac's connections to its own LAN address use the loopback interface, which
the rules allow. To show port 3001 blocked, connect from a third device on the
same Wi-Fi (for example a phone browser at `http://MILIND:3001/`) or watch the
rule counters with `sudo pfctl -a com.apple/team18 -vsr`.

Roll back on each Mac:

```sh
sudo pfctl -a com.apple/team18 -F all
sudo pfctl -X <token>                      # releases this enable; pf returns to its earlier state
sudo pfctl -a com.apple/team18 -sr         # prints nothing once the rules are gone
sudo pfctl -s info | head -1
```

## D. High-availability failover

The edge probes `/api/status` on each backend every 2 seconds with a
1-second timeout. A request that fails, or a backend answering with a 5xx
status, also marks that backend down for 10 seconds, and `lb_try_duration`
retries the request on the other backend, so clients see no errors.

```sh
for i in 1 2 3 4 5 6; do curl -s -D - -o /dev/null https://app.team18.test/api/status | grep -i x-backend; done
```

1. Both running: the header alternates between A and B.
2. Stop Backend A (Ctrl-C on Milind's Mac): every response is `200` from B.
3. Start Backend A again: within a few seconds the header alternates again.

The edge itself is still a single point of failure: if Caddy or Isha's Mac
stops, nothing serves `app.team18.test`. Removing it needs a second edge that
takes over the same address (a floating IP managed with VRRP, for example
keepalived) or DNS that returns several edges and drops unhealthy ones. The
DNS servers are no longer a single point of failure after Extension A, and
the backends were not one in Phase 1.

## E. DNS-based edge cutover

Roll back Extension C first. Copy `app.team18.test.pem` and
`app.team18.test-key.pem` from Isha's Mac into `phase2/build/` on Milind's
Mac (the folder is ignored by Git), then start the standby edge:

```sh
cd phase2/build
caddy run --config Caddyfile.standby --adapter caddyfile
```

Both edges add an `X-Edge` header (`primary` or `standby`). Before the change,
every client gets `X-Edge: primary`. Then change the record to Milind's
address as in Extension B. Run on two clients:

```sh
curl -s -D - -o /dev/null https://app.team18.test/api/status | grep -iE 'x-edge|x-backend'
```

A client that resolved the name in the last 30 seconds keeps reaching the
primary edge until its cached answer expires. A client with an empty cache
(flush it first) reaches the standby at once. Both edges keep serving during
the change, which is why a production cutover lowers the TTL in advance and
leaves the old edge running for at least one TTL.

## F. Fault diagnosis

See the [troubleshooting guide](troubleshooting.md).
