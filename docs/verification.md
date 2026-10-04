# Verification guide

Commands that exercise each part of the service. Run them from the repository
root on a client Mac with the scoped resolver configured (see
[DNS setup](dns-setup.md)). The addresses are those in the [README](../README.md#network-addresses).

## Local setup and tests

```sh
# Network details on each Mac
ifconfig en0
route -n get default

# Backend tests
node --test phase1/backend/*.test.js

# Validate the DNS configuration
/opt/homebrew/sbin/dnsmasq --test --conf-file=phase1/configs/dnsmasq-team18.conf
```

## DNS and direct backends

```sh
dig @10.7.20.246 app.team18.test A +time=2 +tries=1
dig @10.7.20.246 example.com A +time=2 +tries=1
nslookup app.team18.test 10.7.20.246
dscacheutil -q host -a name app.team18.test

curl -i --max-time 8 http://10.7.20.246:3001/
curl -i --max-time 8 http://10.7.20.246:3001/api/status
curl -i --max-time 8 http://10.7.16.207:3002/api/status
```

`dig` and `nslookup` name the server explicitly. The scoped macOS resolver is
exercised by `dscacheutil`, the browser, and ordinary curl.

## HTTPS and balancing

```sh
curl -v --max-time 8 https://app.team18.test/api/status
curl --http1.1 -i --max-time 8 https://app.team18.test/api/status
curl --http2 -i --max-time 8 https://app.team18.test/api/status

for request in 1 2 3 4 5 6 7 8; do
  curl -sS --max-time 8 -D - -o /dev/null https://app.team18.test/api/status
done
```

Read the `X-Backend` header to see which backend answered. Certificate
verification stays enabled throughout. Check both identities while both
backends are healthy, because the health checker removes an unavailable one.

## Cache revalidation

```sh
# Directly against Backend A
curl -i --max-time 8 http://10.7.20.246:3001/api/cache
curl -i --max-time 8 -H 'If-None-Match: "backend-a-cache-v1"' \
  http://10.7.20.246:3001/api/cache

# Through the HTTPS proxy
curl -i --max-time 8 https://app.team18.test/api/cache
curl -i --max-time 8 -H 'If-None-Match: "backend-b-cache-v1"' \
  https://app.team18.test/api/cache
```

The direct test to A returns `200`, then `304`. Through the proxy, the
conditional request returns `304` when B is selected and `200` when A is
selected, because their bodies and ETags differ. In Chrome DevTools, inspect
`Cache-Control`, `ETag`, `If-None-Match`, and the status code.

## Packet capture

Capture on the client's Wi-Fi interface for DNS and HTTPS traffic, and on the
loopback interface `lo0` for plain-HTTP requests to a local backend.

| Display filter | Shows |
| --- | --- |
| `dns` | Query names, source and destination, A-record answers |
| `tcp.flags.syn == 1` | SYN and SYN-ACK; inspect the following ACK |
| `tls` | ClientHello, ServerHello, encrypted records |
| `http` | Readable GET requests and responses on loopback |
| `tcp.port == 8443` | SYN followed by RST/ACK when the port is unused |

A loopback HTTP capture does not show TLS. With TLS 1.3, the server's
certificate message is encrypted after ServerHello, so certificate trust is
shown with curl and Chrome rather than in the packet view.

## Failure checks

```sh
# Unknown hostname
dig @10.7.20.246 not-app.team18.test A +time=2 +tries=1

# Unused proxy port
curl -i --max-time 8 https://app.team18.test:8443/api/status

# Wrong destination (this overrides the connection address; it is not a DNS query)
curl -i --max-time 8 --resolve app.team18.test:443:127.0.0.1 \
  https://app.team18.test/api/status
```

For a DNS-layer wrong answer, run a separate test DNS server on port 1053 and
leave the port-53 service unchanged.

To test backend failures, stop only the relevant backend process. With
Backend A stopped, wait for the health check and repeat the HTTPS status
request: Backend B serves it. With both stopped, Caddy returns `503`. Restart
the backends afterward and confirm that both identities respond again.
