# HTTPS proxy

## Configuration

The [Caddyfile](../phase1/configs/Caddyfile) serves `app.team18.test` on HTTPS
port 443. It proxies to Backend A at `10.7.20.246:3001` and to Backend B at
`127.0.0.1:3002`. It uses round-robin selection, checks `/api/status` every
two seconds, and retries failed upstream connections for up to two seconds.

TLS protects the client-to-Caddy connection. Caddy-to-backend traffic is plain
HTTP on the LAN or loopback.

[Backend B](../phase1/backend/backend-b.js) listens on `0.0.0.0:3002`. Like
Backend A, it serves `/`, `/api/status` and `/api/cache`, adds `X-Backend: B`,
and supports ETag revalidation.

## Certificate

The certificate for `app.team18.test` is issued by a local mkcert certificate
authority. The Caddyfile loads `app.team18.test.pem` and
`app.team18.test-key.pem` from the directory it runs in. Neither file is in
this repository, and the private key stays on the proxy's Mac. A client must
trust the mkcert authority before it will accept the certificate; see the
[certificate notes](../phase1/tls/README.md).

## Running

1. Start Backend A on Milind's Mac and Backend B on Isha's Mac:

   ```sh
   node phase1/backend/backend-a.js
   node phase1/backend/backend-b.js
   ```

2. On the proxy Mac, with the certificate files beside the Caddyfile:

   ```sh
   caddy validate --config Caddyfile --adapter caddyfile
   caddy start --config Caddyfile --adapter caddyfile
   ```

3. From either client Mac, request the service without bypassing verification:

   ```sh
   curl -i https://app.team18.test/api/status
   ```

   Repeated requests show `X-Backend` alternating between A and B.

See the [verification guide](verification.md) for cache, balancing and
failure checks.
