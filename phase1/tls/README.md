# Team 18 certificate record

Isha generated the project certificate with mkcert. The deployed Caddyfile
loads `app.team18.test.pem` and `app.team18.test-key.pem` from
`/Users/ishatomar/team18-proxy/`. Those certificate files are not currently
included in this checkout. The private key stays on Isha's Mac.

Milind verified the public `rootCA.cer` before trusting it for SSL in his
login keychain. The supplied and checked SHA-256 fingerprint was:

```text
F7:06:67:00:02:29:07:3C:BF:4C:F6:38:9E:DD:60:14:9F:D0:C4:32:99:18:D4:AE:29:4D:1D:D7:14:B0:AC:67
```

See [TLS setup](../../docs/tls-setup.md) for startup and verification.

The public CA is needed when preparing another client. Obtain the actual
Team 18 certificate from Isha and verify its fingerprint; a certificate from
the reference repository belongs to that separate project.
