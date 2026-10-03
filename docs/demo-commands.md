# Team 18 demo commands

Run from the repository root unless a step names Isha's deployed directory.
The commands use recorded DHCP addresses. Confirm both Macs' current IPs
first, along with service ports and the scoped resolver. Live remote checks
were not passing at the last follow-up. Packet captures and command output
are not bundled with the repository.

## Local setup and tests

```sh
# Network snapshot on each Mac
ifconfig en0
route -n get default

# Run all backend tests locally
node --test phase1/backend/*.test.js

# Check the tracked DNS configuration
/opt/homebrew/sbin/dnsmasq --test --conf-file=phase1/configs/dnsmasq-team18.conf
```

Start only missing services. A runs on Milind's Mac with
`node phase1/backend/backend-a.js`; B runs on Isha's Mac with
`node phase1/backend/backend-b.js` from her checkout, or `node backend-b.js`
from the existing `~/team18-proxy` deployment. See [TLS setup](tls-setup.md)
for Caddy and [DNS setup](dns-setup.md) for dnsmasq and the clients.

## DNS and direct backends

```sh
dig @10.7.20.246 app.team18.test A +time=2 +tries=1
dig @10.7.20.246 example.com A +time=2 +tries=1
nslookup app.team18.test 10.7.20.246
dscacheutil -q host -a name app.team18.test

curl -i --max-time 8 http://10.7.20.246:3001/
curl -i --max-time 8 http://10.7.20.246:3001/api/status
curl -i --max-time 8 http://10.7.23.42:3002/api/status
```

`dig` and `nslookup` use an explicit server here: macOS's domain-specific
resolver is verified by `dscacheutil`, the browser, and ordinary curl.

## HTTPS and balancing

```sh
curl -v --max-time 8 https://app.team18.test/api/status
curl --http1.1 -i --max-time 8 https://app.team18.test/api/status
curl --http2 -i --max-time 8 https://app.team18.test/api/status

for request in 1 2 3 4 5 6 7 8; do
  curl -sS --max-time 8 -D - -o /dev/null https://app.team18.test/api/status
done
```

Read `X-Backend` to identify A or B. Certificate verification stays enabled.
The health checker can affect selection while a backend is unavailable;
check both backend identities while the upstreams are healthy.

## Cache revalidation

```sh
# Deterministic test against A
curl -i --max-time 8 http://10.7.20.246:3001/api/cache
curl -i --max-time 8 -H 'If-None-Match: "backend-a-cache-v1"' \
  http://10.7.20.246:3001/api/cache

# Through the HTTPS proxy
curl -i --max-time 8 https://app.team18.test/api/cache
curl -i --max-time 8 -H 'If-None-Match: "backend-b-cache-v1"' \
  https://app.team18.test/api/cache
```

The direct A test should return `200`, then `304`. The proxy conditional
request returns `304` when B is selected and `200` when A is selected because
their cache bodies and ETags differ. In Chrome DevTools, inspect
`Cache-Control`, `ETag`, `If-None-Match`, and the status code.

## Wireshark views for the video

Capture fresh DNS and HTTPS traffic on the client Mac's Wi-Fi interface.
For local Backend A HTTP requests, use the loopback interface `lo0`.

| Display filter | Inspect |
| --- | --- |
| `dns` | Query names, source/destination, A-record answers |
| `tcp.flags.syn == 1` | SYN and SYN-ACK; inspect the following ACK |
| `tls` | ClientHello, ServerHello, encrypted records |
| `http` | Readable GET and response on loopback |
| `tcp.port == 8443` | SYN followed by RST/ACK when the port is unused |

A loopback HTTP capture does not show TLS. With TLS 1.3, the server certificate
message is encrypted after ServerHello; demonstrate certificate trust through
curl and Chrome rather than claiming it is readable in the unencrypted
packet view. Store recordings and packet captures outside this repository.

## Failure checks and restoration

```sh
# Wrong hostname
dig @10.7.20.246 not-app.team18.test A +time=2 +tries=1

# Wrong proxy port
curl -i --max-time 8 https://app.team18.test:8443/api/status

# Isolate a deliberately wrong HTTPS destination
curl -i --max-time 8 --resolve app.team18.test:443:127.0.0.1 \
  https://app.team18.test/api/status
```

The last command isolates destination behavior; it is not a DNS query.
For a DNS-layer wrong-IP test, use an isolated test server on port 1053.
Leave the working port-53 DNS configuration unchanged.

For backend failures, stop only the relevant project process in its owning
Terminal. With A stopped, wait for the health check and repeat HTTPS status
requests: B should serve them. With both backends stopped, expect `503`.
Restart A and B in their own Terminals, then confirm direct status, trusted
HTTPS, and responses from both backend identities. Do not stop unrelated
Node.js processes.

Record the relevant output in the demo video and confirm restoration before
ending the recording.
