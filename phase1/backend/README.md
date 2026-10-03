# Phase 1 backends

Two Node.js standard-library servers. No npm install is needed.
Run commands from the repository root; run A on Milind's Mac and B on Isha's.

```sh
node phase1/backend/backend-a.js
node phase1/backend/backend-b.js
```

Each command stays in the foreground in its own Terminal. A listens on
`0.0.0.0:3001`; B listens on `0.0.0.0:3002`. Isha's previously deployed
copy remains in `~/team18-proxy`, where `node backend-b.js` starts B.
Moving the repository files does not move that deployed copy.

| Route | Behavior |
| --- | --- |
| `GET /` | Plain-text greeting naming the backend |
| `GET /api/status` | JSON with `status: ok` and backend identity |
| `GET /api/cache` | Plain text, `Cache-Control: max-age=60`, and an ETag |
| Matching cache `If-None-Match` | `304` with no response body |
| Other request | `404` |

Every response identifies its backend through `X-Backend`. A and B have
different cache bodies and ETags. These servers implement GET routes;
use `curl -i` with GET for header demonstrations rather than `curl -I`.

```sh
node --test phase1/backend/*.test.js
```

The five tests cover root/status identity, cache revalidation, and A's
unknown-route response. Tests start temporary localhost servers; they need
permission to bind local sockets. See [demo commands](../../docs/demo-commands.md)
and [configuration](../configs/README.md).
