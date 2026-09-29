# HTTPS proxy and Backend B

## Live recheck, 2026-09-29

The original `~/team18-proxy/Caddyfile` is running on Aarohi's Mac. Both
backends answer directly. Trusted HTTPS, DNS, and cache revalidation work.
During diagnosis, eight HTTPS requests reached only B; Caddy logged
`dial tcp 10.7.20.246:3001: connect: no route to host` even while Aarohi's
`curl` reached A directly. After the original Caddy listener was restored,
12 consecutive HTTPS requests alternated B/A. This intermittent route needs
another check before the demo. Temporary diagnostic listeners were stopped,
and Backend A's temporary request logging was removed.


On Aarohi's Mac (`10.7.23.42` during the 2026-09-29 test), Caddy 2.11.4 listens on port 443 with the `app.team18.test` certificate. It forwards requests over plain HTTP to Backend A on Milind's Mac (`10.7.20.246:3001`) and Backend B on Aarohi's Mac (`127.0.0.1:3002`). The TLS handshake and encrypted application data are on the client-to-Caddy connection; backend HTTP is not encrypted.

The [Caddyfile](../proxy/Caddyfile) uses `round_robin`, checks `/api/status` every 2 seconds, and retries failed upstream connections for up to 2 seconds. These directives follow [Caddy's reverse proxy documentation](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy). The deployed copy is `~/team18-proxy/Caddyfile` on Aarohi's Mac; `Caddyfile.before-balancing` preserves her original A-only config. The certificate and private key remain only on her Mac.

Backend B is [implemented](../backend-b.js) and [tested](../backend-b.test.js) in this repo. The same files were copied to `~/team18-proxy` on Aarohi's Mac. It listens on `0.0.0.0:3002`, identifies itself in `X-Backend: B`, and serves `/`, `/api/status`, and `/api/cache` with ETag revalidation.

The 2026-09-29 results, all captured from Milind's Mac, are indexed in [the evidence folder](../evidence/README.md):

| Test | Result |
| --- | --- |
| Eight HTTPS status requests | A, B, A, B, A, B, A, B |
| Backend A stopped | Four `200` responses from B |
| Both backends stopped | Caddy returned `503` |
| Both restored | Follow-up requests alternated A/B |
| Cache request with B's ETag | B returned `304`; A returned its own `200` representation and ETag |

The A/B and failure captures used curl's `--resolve` to isolate proxy behavior while dnsmasq was stopped. After dnsmasq restarted, requests without `--resolve` succeeded from both Macs over trusted HTTPS. Caddy was started with `XDG_DATA_HOME` and `XDG_CONFIG_HOME` pointing to writable user-owned paths because the default Caddy storage directory on Aarohi's Mac is root-owned. Its config autosave and storage cleanup then succeeded.
