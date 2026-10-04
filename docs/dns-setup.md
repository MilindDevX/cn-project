# DNS setup

## Network

| Item | Value |
| --- | --- |
| DNS server | Milind's Mac, `10.7.20.246` (Wi-Fi `en0`) |
| Network | `10.7.0.0/19`, mask `255.255.224.0`, gateway `10.7.0.1` |
| Proxy host | Isha's Mac, `10.7.16.207` |

Both Macs receive their addresses by DHCP. Check them with `ifconfig en0` and
`route -n get default`. If either address changes, update the DNS record and
the Caddy upstream in the [configuration files](../phase1/configs/README.md).

## DNS server

Homebrew dnsmasq runs on Milind's Mac at port 53. The
[configuration](../phase1/configs/dnsmasq-team18.conf) maps `app.team18.test`
to the proxy's address and listens on `127.0.0.1` and `10.7.20.246`. The
deployed copy is `/opt/homebrew/etc/dnsmasq.d/team18.conf`. All other names
are forwarded to `8.8.8.8`.

Start it with:

```sh
sudo /opt/homebrew/bin/brew services start dnsmasq
```

## Clients

Each client Mac keeps its Wi-Fi DNS setting on automatic and uses a scoped
resolver that sends only the project domain to Milind's server. Create
`/etc/resolver/team18.test` containing:

```text
nameserver 10.7.20.246
```

A scoped resolver keeps unrelated names on the normal network DNS path, so
internet access works even when the project DNS server is stopped. Do not add
the project hostname to `/etc/hosts`; that would bypass DNS.

## Checks

```sh
dig @10.7.20.246 app.team18.test A
dig @10.7.20.246 example.com A
nslookup app.team18.test 10.7.20.246
```

The first command returns the proxy address. The second shows that other
names are forwarded. See the [verification guide](verification.md) for the
full command list, and [TLS setup](tls-setup.md) for the HTTPS side.
