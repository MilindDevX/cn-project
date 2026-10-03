# HTTPS proxy — Isha's Mac

## Configuration

[Backend B](../phase1/backend/backend-b.js) listens on `0.0.0.0:3002`.
Like A, it serves `/`, `/api/status`, and `/api/cache`, adds `X-Backend: B`,
and supports ETag revalidation. Run the tracked tests from the repo root:

```sh
node --test phase1/backend/backend-b.test.js
```

The tracked [Caddyfile](../phase1/configs/Caddyfile) serves `app.team18.test` on HTTPS
port 443. It proxies to Backend A at `10.7.20.246:3001` on Milind's Mac and
Backend B at `127.0.0.1:3002` on Isha's Mac. It uses round-robin selection,
checks `/api/status` every two seconds, and retries failed upstream
connections for up to two seconds. TLS protects the client-to-Caddy
connection. Caddy-to-backend HTTP is unencrypted on the LAN or loopback.

The Caddyfile points to certificate files on Isha's Mac. Only their paths
are tracked here; the private key is not in this repository. On 2026-09-29,
the deployed Caddyfile and Backend B source in `~/team18-proxy` on Isha's Mac
matched the tracked versions. Caddy was version 2.11.4 and used a separate
writable storage location because its default storage directory was
root-owned on her Mac.

## Before a demo

1. Connect both Macs to the same LAN. Check their current IP addresses against
   the [DNS configuration](dns-setup.md) and the Caddyfile. Check whether
   ports 3001, 3002, and 443 are already listening.
2. Start only missing services. From Milind's repo root, Backend A starts
   with `node phase1/backend/backend-a.js`. From `~/team18-proxy` on Isha's
   Mac, Backend B starts with `node backend-b.js`.
3. If Caddy is not listening, run on Isha's Mac:

   ```sh
   cd ~/team18-proxy
   XDG_DATA_HOME="$HOME/.local/share/team18-caddy" XDG_CONFIG_HOME="$HOME/.config/team18-caddy" caddy start --config Caddyfile --adapter caddyfile
   ```

4. Check both backends directly. From both Macs, repeat
   `curl -i https://app.team18.test/api/status` without `--resolve` or `-k`.
   Verify that the certificate is trusted and `X-Backend` shows both A and B.

Use the [demo commands](demo-commands.md) to verify trusted HTTPS, cache
revalidation, balancing, and failure behavior before recording.

During a previous integration check, Caddy temporarily sent every request to B and logged
`dial tcp 10.7.20.246:3001: connect: no route to host`, even while curl on
Isha's Mac reached A directly. Restarting the original Caddyfile restored
balancing. The cause was not established. Recheck routing after either Mac
changes networks or restarts.
