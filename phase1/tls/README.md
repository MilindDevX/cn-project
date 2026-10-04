# Certificate

The proxy serves `app.team18.test` with a certificate issued by a local mkcert
certificate authority. The Caddyfile loads `app.team18.test.pem` and
`app.team18.test-key.pem` from the directory it runs in. Those files are not
in this repository, and the private key stays on the proxy's Mac.

A client must trust the mkcert authority before it accepts the certificate.
Obtain the authority's public certificate (`rootCA.cer`) from the proxy owner,
check its SHA-256 fingerprint against the owner's value, and then trust it for
SSL on the client. After that, curl and Chrome verify the certificate normally.

See [TLS setup](../../docs/tls-setup.md) for how the proxy is started.
