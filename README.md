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

See the [DNS setup](docs/dns.md), [evidence](evidence/README.md), and
[HTTPS proxy notes](docs/proxy.md). The DNS record maps `app.team18.test` to
Isha's Mac. During the 2026-09-29 integration test, both Macs used scoped
resolvers for the project domain while Wi-Fi DNS stayed automatic. The
evidence covers DNS and TLS captures, browser headers, balancing, caching,
and failure tests. Recheck LAN addresses and balancing before the demo.
