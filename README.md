# Team 18 · Computer Networks Project

A private HTTPS service running across two Macs. The project demonstrates the
full request path: **DNS → TCP → TLS → reverse proxy → Backend A or B**,
with cache revalidation and failure tests.

| Member | Responsibilities |
| --- | --- |
| Milind | Backend A, dnsmasq, client verification and DNS documentation |
| Isha | Backend B, Caddy HTTPS proxy, certificates, and proxy deployment |

## Scope and verification status

This repository contains the Phase 1 two-Mac implementation. Both backends use
Node.js standard-library HTTP servers; Caddy handles HTTPS and load balancing.
The application needs no npm packages.

Before a live recording or demo, reconfirm both Macs' IPs and services.
The last reachability check confirmed Milind's recorded IP, DNS, and Backend A,
but Isha's SSH, HTTPS, and Backend B ports timed out. A ping reply alone does
not identify the remote Mac.

## Architecture

```mermaid
flowchart LR
    client["Client on either Mac<br/>Chrome or curl"]
    subgraph milind["Milind's Mac · 10.7.20.246"]
        dns["dnsmasq<br/>UDP/TCP 53"]
        a["Backend A · Node.js<br/>TCP 3001"]
    end
    subgraph isha["Isha's Mac · 10.7.23.42"]
        edge["Caddy<br/>HTTPS · TCP 443"]
        b["Backend B · Node.js<br/>TCP 3002"]
    end
    client -->|"DNS query"| dns
    dns -.->|"app.team18.test = 10.7.23.42"| client
    client -->|"TCP + trusted TLS"| edge
    edge -->|"HTTP · LAN"| a
    edge -->|"HTTP · loopback"| b
```

TLS ends at Caddy. Connections from Caddy to the backends use HTTP.
Both clients have a domain-specific macOS resolver for `team18.test`; their
Wi-Fi DNS settings remain automatic for other domains.

See the [architecture guide](docs/architecture.md) for the request sequence,
network inventory, and operational limits.

## Network inventory

The addresses below are recorded DHCP assignments, not permanent addresses.

| Host | Recorded address | Service | Port |
| --- | --- | --- | --- |
| Milind's Mac | `10.7.20.246` | dnsmasq | UDP/TCP 53 |
| Milind's Mac | `10.7.20.246` | Backend A | TCP 3001 |
| Isha's Mac | `10.7.23.42` | Caddy | TCP 443 |
| Isha's Mac | `10.7.23.42` | Backend B | TCP 3002 |

Milind's recorded interface is `en0`, subnet mask `255.255.224.0` (`/19`),
and gateway `10.7.0.1`. Caddy addresses Backend B as `127.0.0.1:3002`
because it runs on the same Mac. See [DNS setup](docs/dns-setup.md) for the
recorded LAN snapshot and resolver settings.

## Services

### DNS

[dnsmasq-team18.conf](phase1/configs/dnsmasq-team18.conf) serves the exact record:

```text
app.team18.test → 10.7.23.42
```

It binds to Milind's loopback and LAN addresses and forwards public names to
`8.8.8.8`. The saved team-record response has TTL `0`; no custom DNS TTL is
configured. Each Mac's `/etc/resolver/team18.test` contains:

```text
nameserver 10.7.20.246
```

Public Wi-Fi DNS stays automatic. The project hostname must resolve through
DNS for the demonstration; an `/etc/hosts` entry would bypass that exchange.

### Backends

| Request | Backend A | Backend B |
| --- | --- | --- |
| `GET /` | `Hello from Backend A` | `Hello from Backend B` |
| `GET /api/status` | `{"status":"ok","backend":"A"}` | `{"status":"ok","backend":"B"}` |
| `GET /api/cache` | Cacheable body, A's ETag | Cacheable body, B's ETag |
| Matching `If-None-Match` on `/api/cache` | `304`, empty body | `304`, empty body |
| Unknown route | `404` | `404` |

Each backend adds its own `X-Backend` header. The cache endpoint sends
`Cache-Control: max-age=60`. A and B have different bodies and ETags;
a validator from B can return `304` on B and `200` on A.

Start each backend on its assigned Mac from the repository root:

```sh
# Milind's Mac
node phase1/backend/backend-a.js

# Isha's Mac
node phase1/backend/backend-b.js
```

Run all five endpoint tests locally:

```sh
node --test phase1/backend/*.test.js
```

See [backend instructions](phase1/backend/README.md).

### HTTPS and load balancing

The [Caddyfile](phase1/configs/Caddyfile) selects A or B using round robin,
checks `/api/status` every two seconds, and retries failed upstream
connections for up to two seconds. Use curl to check the negotiated TLS and HTTP versions.
Caddy's connections to the Node.js backends use HTTP/1.1.

Isha's mkcert CA was checked against the supplied SHA-256 fingerprint and
trusted for SSL in Milind's login keychain. Curl verified the project
certificate without `-k`, and Chrome reported a valid certificate.
Certificate and private-key files remain in Isha's deployed directory.
See [TLS and proxy setup](docs/tls-setup.md) and the
[certificate record](phase1/tls/README.md).

## Repository structure

```text
.
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── demo-commands.md
│   ├── dns-setup.md
│   ├── form-submission-checklist.md
│   └── tls-setup.md
└── phase1/
    ├── backend/
    │   ├── README.md
    │   ├── backend-a.js
    │   ├── backend-a.test.js
    │   ├── backend-b.js
    │   └── backend-b.test.js
    ├── configs/
    │   ├── README.md
    │   ├── dnsmasq-team18.conf
    │   └── Caddyfile
    └── tls/
        └── README.md
```

## Quick verification

These commands assume the recorded IPs still belong to the correct Macs and
both services are running. They use GET because the backends implement GET
routes. Run from a configured client:

```sh
# DNS server and public forwarding
dig @10.7.20.246 app.team18.test A
dig @10.7.20.246 example.com A
nslookup app.team18.test 10.7.20.246

# Direct backend status
curl -i --max-time 8 http://10.7.20.246:3001/api/status
curl -i --max-time 8 http://10.7.23.42:3002/api/status

# Normal macOS DNS and certificate verification
curl -i --max-time 8 https://app.team18.test/api/status

# Backend A's deterministic cache revalidation
curl -i --max-time 8 http://10.7.20.246:3001/api/cache
curl -i --max-time 8 -H 'If-None-Match: "backend-a-cache-v1"' \
   http://10.7.20.246:3001/api/cache
```

The [demo command guide](docs/demo-commands.md) includes balancing, HTTPS
cache checks, Wireshark filters, and failure-test instructions.

## Verification checklist

| Check | Expected result |
| --- | --- |
| DNS from both Macs | `app.team18.test` resolves to Isha's current IP |
| HTTPS trust | Chrome and curl accept the certificate without bypassing verification |
| Backend identity | Responses contain `X-Backend: A` or `B` |
| Healthy balancing | Repeated requests reach both backends |
| Cache revalidation | `max-age=60`, ETag, and matching conditional `304` |
| Wrong hostname | `NXDOMAIN` for an unknown team hostname |
| Wrong IP or port | Connection fails when no service listens at the selected destination |
| Backend A down | Backend B continues serving successful responses |
| Both backends down | Caddy returns `503` |

Use [demo commands](docs/demo-commands.md) to repeat these checks and
[the submission checklist](docs/form-submission-checklist.md) to prepare the
five-minute video. Test output, packet captures, and screenshots are not
included in this repository.

## Demo and operational limits

- Recheck both DHCP addresses, certificate trust, service ports, and balancing.
- Caddy once temporarily routed only to B and logged `no route to host` for A.
  Restarting restored balancing; the cause was not established.
- dnsmasq was registered with launchd, but startup after reboot was not tested.
- The five-minute demo video will be added later, with approximately
  **2 minutes 30 seconds each** for Milind and Isha.
- Use the [submission checklist](docs/form-submission-checklist.md) to check
  required demonstrations and final sharing access.
