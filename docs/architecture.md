# Architecture

## Service placement

| Mac | Address | Services |
| --- | --- | --- |
| Milind's | `10.7.20.246` | dnsmasq on 53, Backend A on 3001 |
| Isha's | `10.7.16.207` | Caddy on 443, Backend B on 3002 |

Both Macs are on `10.7.0.0/19` and receive addresses by DHCP. The
[README diagram](../README.md#architecture) shows which services share each Mac.

## Request sequence

```mermaid
sequenceDiagram
    participant Client as Client on either Mac
    participant DNS as Milind's dnsmasq :53
    participant Edge as Isha's Caddy :443
    participant A as Milind's Backend A :3001
    participant B as Isha's Backend B :3002
    Client->>DNS: Query app.team18.test
    DNS-->>Client: A record 10.7.16.207
    Client->>Edge: TCP three-way handshake, then TLS
    Client->>Edge: Encrypted HTTP request
    alt Backend A selected
        Edge->>A: HTTP request over LAN
        A-->>Edge: Response with X-Backend A
    else Backend B selected
        Edge->>B: HTTP request over loopback
        B-->>Edge: Response with X-Backend B
    end
    Edge-->>Client: Encrypted HTTPS response
```

The client receives an A record for the proxy, not a backend address. Caddy
terminates TLS and makes a separate HTTP/1.1 connection to the selected
backend. Round-robin selection, active health checks every two seconds, and
upstream retry behavior are configured in the
[Caddyfile](../phase1/configs/Caddyfile).

## DNS and trust

Both Macs use a scoped macOS resolver for `team18.test`; other names keep
using the normal network DNS. The
[dnsmasq configuration](../phase1/configs/dnsmasq-team18.conf) serves the
project record and forwards other names to `8.8.8.8`. It sets no custom TTL.

The proxy uses a certificate issued by a local mkcert certificate authority.
Clients trust that authority, so curl and Chrome accept the certificate
without bypassing verification. The certificate and private key stay on the
proxy's Mac; see [TLS setup](tls-setup.md).

## Cache and availability behavior

Each backend identifies itself with an `X-Backend` header. `/api/cache` sends
a 60-second freshness lifetime and a backend-specific ETag. A conditional
request returns `304` only when its validator matches the selected backend's
representation. A validator from B that is routed to A returns A's body with
`200`.

With Backend A down, Backend B continues to answer with `200`. With both
backends down, Caddy returns `503`.
