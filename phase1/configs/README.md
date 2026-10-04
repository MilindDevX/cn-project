# Configuration

| File | Purpose | Deployed location |
| --- | --- | --- |
| [dnsmasq-team18.conf](dnsmasq-team18.conf) | DNS record for `app.team18.test`; forwards other names | `/opt/homebrew/etc/dnsmasq.d/team18.conf` on Milind's Mac |
| [Caddyfile](Caddyfile) | HTTPS reverse proxy and load balancer | Next to the certificate files on Isha's Mac |

Both files use the addresses in the [README](../../README.md#network-addresses):
the DNS record points to the proxy, and the Caddy upstreams point to the two
backends. If a DHCP address changes, update the matching entry here.

Validate the DNS file from the repository root:

```sh
/opt/homebrew/sbin/dnsmasq --test --conf-file=phase1/configs/dnsmasq-team18.conf
```

Validate the Caddy file from the directory that holds the certificate files:

```sh
caddy validate --config Caddyfile --adapter caddyfile
```

See [DNS setup](../../docs/dns-setup.md) and [TLS setup](../../docs/tls-setup.md).
