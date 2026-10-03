# DNS setup — Milind's Mac

## Recorded LAN addresses

Snapshot from September 2026. Both Macs use DHCP; recheck their addresses
before each demo.

| Item | Recorded value |
| --- | --- |
| Milind's interface | Wi-Fi (`en0`) |
| Milind's IPv4 | `10.7.20.246` |
| Subnet mask | `255.255.224.0` (`/19`) |
| Network | `10.7.0.0/19` |
| Gateway | `10.7.0.1` |
| Milind's Wi-Fi MAC | `32:f4:e3:a0:0f:ef` |
| Isha's IPv4 | `10.7.23.42` |

Check with `ifconfig en0` and `route -n get default` on each Mac.

## DNS server and clients

Homebrew dnsmasq runs on Milind's Mac at port 53. The tracked
[configuration](../phase1/configs/dnsmasq-team18.conf) maps `app.team18.test`
to Isha's recorded IP and listens on `127.0.0.1` and `10.7.20.246`. Its
deployed copy is `/opt/homebrew/etc/dnsmasq.d/team18.conf`. Other names are
forwarded to `8.8.8.8`.

Keep both Macs' Wi-Fi DNS settings automatic. Each Mac uses
`/etc/resolver/team18.test` to route only the project domain to Milind's server:

```text
nameserver 10.7.20.246
```

Milind previously lost internet access when setting his whole Wi-Fi DNS to
his own server. The scoped resolver keeps unrelated names on the normal
network DNS path. Do not add the project hostname to `/etc/hosts`, which
would bypass the DNS exchange.

## Before a demo

1. Check both Macs' current LAN IPs. Update the deployed DNS and Caddy
   configs if DHCP changed either address.
2. If DNS is stopped on Milind's Mac, start it in his Terminal with
   `sudo /opt/homebrew/bin/brew services start dnsmasq`.
3. From either Mac, run `dig @10.7.20.246 app.team18.test A` and
   `dig @10.7.20.246 example.com A`. From Isha's Mac, also run
   `nslookup app.team18.test 10.7.20.246`.
4. Confirm `/etc/resolver/team18.test` has the current DNS-server IP on
   both Macs, then request `https://app.team18.test/api/status` without
   curl's `--resolve` or `-k` options.

For service diagnostics, dnsmasq was previously registered as
`system/sh.brew.dnsmasq` under launchd with `RunAtLoad` and `KeepAlive`.
`brew services list` did not reflect that running service. Check a live DNS
query or launchd when status is unclear; restart after reboot was not tested.

## HTTPS and failure checks

Isha's public mkcert CA must be trusted by the client. Verify its fingerprint
before installing trust; see the [certificate record](../phase1/tls/README.md)
and [TLS setup](tls-setup.md).

Use [demo commands](demo-commands.md) to check an unknown team hostname,
a deliberately wrong destination, an unused proxy port, and one or both
backends stopped. Restore both backends and confirm trusted HTTPS and A/B
responses afterward. Keep test DNS changes isolated from the live service.
