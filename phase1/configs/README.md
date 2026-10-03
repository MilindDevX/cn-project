# Phase 1 configuration

| File | Owner and deployed location |
| --- | --- |
| [dnsmasq-team18.conf](dnsmasq-team18.conf) | Milind; `/opt/homebrew/etc/dnsmasq.d/team18.conf` |
| [Caddyfile](Caddyfile) | Isha; `~/team18-proxy/Caddyfile` |

Both files use the recorded DHCP addresses. Before installing an updated copy,
confirm Milind's and Isha's current IPs and compare against the DNS record and
Caddy upstream. The certificate paths in Caddy refer to Isha's Mac.
Repository reorganization does not update either deployed configuration.

Validate the tracked DNS file from the repository root:

```sh
/opt/homebrew/sbin/dnsmasq --test --conf-file=phase1/configs/dnsmasq-team18.conf
```

On Isha's Mac, with the deployed certificate files available:

```sh
cd ~/team18-proxy
caddy validate --config Caddyfile --adapter caddyfile
```

See [DNS installation and resolver settings](../../docs/dns-setup.md) and
[Caddy startup and certificate verification](../../docs/tls-setup.md).
Do not start duplicate services when the existing service already owns its port.
