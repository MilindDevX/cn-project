# CN project — Milind's half

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

See [DNS setup](docs/dns.md) and [evidence index](evidence/README.md). Backend B runs on Aarohi Mac at port 3002. The [Caddyfile](proxy/Caddyfile) balances A and B over HTTPS; certificate files remain on Aarohi Mac.
