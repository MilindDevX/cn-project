# HTTPS proxy and Backend B

## Configuration

[Backend B](../backend-b.js) listens on `0.0.0.0:3002`. It serves `/`,
`/api/status`, and `/api/cache`, identifies itself with `X-Backend: B`, and
supports ETag revalidation. Its [tests](../backend-b.test.js) run with
`node --test backend-b.test.js`.

Isha's [Caddyfile](../proxy/Caddyfile) serves `app.team18.test` on HTTPS port
443. It forwards to Backend A at `10.7.20.246:3001` and Backend B at
`127.0.0.1:3002`, rotates requests with `round_robin`, checks `/api/status`
every two seconds, and retries failed upstream connections for up to two
seconds. TLS protects the client-to-Caddy connection; Caddy-to-backend HTTP is
unencrypted. The certificate and private key paths are in the Caddyfile. Their
contents remain on Isha's Mac.

On 2026-09-29, the deployed Caddyfile and Backend B source in
`~/team18-proxy` on Isha's Mac matched the committed files. Her Caddy
version was 2.11.4. The project uses writable Caddy storage paths because
the default storage directory on her Mac was root-owned.

## Start and check before the demo

Connect both Macs to the same LAN. Check their current IP addresses against
the Caddyfile and [DNS configuration](dns.md); the recorded addresses are
DHCP assignments. Check whether ports 3001 on Milind's Mac and 3002 and
443 on Isha's Mac are already listening. Start only missing services:
Backend A with `node backend-a.js` from Milind's repo, and Backend B with
`node backend-b.js` from `~/team18-proxy` on Isha's Mac. If Caddy is not
listening, run this in another Terminal on her Mac:

```sh
cd ~/team18-proxy
XDG_DATA_HOME="$HOME/.local/share/team18-caddy" XDG_CONFIG_HOME="$HOME/.config/team18-caddy" caddy start --config Caddyfile --adapter caddyfile
```

Check both backends directly, then run
`curl -i https://app.team18.test/api/status` repeatedly from both Macs.
Verify the certificate is trusted and `X-Backend` alternates A/B. See the
[evidence index](../evidence/README.md) for DNS, TCP, TLS, browser, cache, and
failure captures from Milind's Mac.

## Recorded results and risk

On 2026-09-29, trusted HTTPS, A/B balancing, cache `200` and conditional
`304`, A-down B-only `200`, and both-down `503` passed. After both backends
were restored, 12 requests spaced five seconds apart alternated A/B. The
[live recheck](../evidence/local/live-recheck-2026-09-29.txt) records these
results.

Earlier that day, Caddy temporarily sent every request to B and logged
`dial tcp 10.7.20.246:3001: connect: no route to host` even while `curl` on
Isha's Mac reached A directly. Restarting with the original Caddyfile
restored balancing. The cause was not established. Recheck routing before
the demo, especially after either Mac changes networks or restarts.
