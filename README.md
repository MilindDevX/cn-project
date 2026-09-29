# CN project — Team 18

Backend A runs on `0.0.0.0:3001` with Node.js. No packages required.

```sh
node backend-a.js
node --test backend-a.test.js
```

| Request | Response |
| --- | --- |
| `GET /` | `Hello from Backend A` |
| `GET /api/status` | `{"status":"ok","backend":"A"}` |
| `GET /api/cache` | `Cache-Control: max-age=60`, `ETag`, and a cacheable body |
| `GET /api/cache` with matching `If-None-Match` | `304 Not Modified` |

Every response includes `X-Backend: A`.

See [DNS setup](docs/dns.md), [evidence](evidence/README.md), and Aarohi's
[HTTPS proxy notes](docs/proxy.md). The DNS record points `app.team18.test` to
Aarohi's Mac. Both Macs use a domain-specific resolver, leaving ordinary Wi-Fi
DNS automatic. The evidence includes DNS and TLS captures, browser headers,
A/B balancing, cache revalidation, and failure tests. Recheck the Macs' current
LAN addresses and the live balance before the demo.
