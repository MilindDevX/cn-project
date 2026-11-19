# Troubleshooting

Work from the bottom of the stack up and stop at the first layer that fails.
The script runs every check in order:

```sh
phase2/scripts/diagnose.sh MILIND_IP ISHA_IP
```

| Layer | Check | If it fails, look at |
| --- | --- | --- |
| DNS | `dig @MILIND_IP app.team18.test`, the same against `ISHA_IP`, then `dscacheutil -q host -a name app.team18.test` | dnsmasq running, `/opt/homebrew/etc/team18.hosts`, `/etc/resolver/team18.test`, stale client cache |
| IP | `ping EDGE_IP` | Wrong address in the record, edge Mac offline, changed DHCP address |
| TCP | `nc -z -G 3 EDGE_IP 443` | Caddy not running, wrong port, pf rule blocking 443 |
| TLS | `openssl s_client -connect EDGE_IP:443 -servername app.team18.test` | Certificate name, expiry, mkcert authority not trusted on the client |
| HTTP | `curl -i https://app.team18.test/api/status` | `502`/`503`: edge up but no backend answers; check the backends and the Caddy upstream addresses |
| Backend | `curl -i http://BACKEND_IP:PORT/api/status` from the edge | Backend process, port, pf isolation rules |

## Symptoms

| Symptom | Layer | Likely cause |
| --- | --- | --- |
| `NXDOMAIN` | DNS | Record missing or misspelled in the hosts file |
| `dig` times out against both servers | DNS | dnsmasq stopped on both Macs, or wrong `listen-address` |
| `dig @server` is right, but the browser goes elsewhere | DNS | Client cache holding an old answer; wait one TTL or flush it |
| `Connection refused` on 443 | TCP | Caddy stopped, or listening on another port |
| Connection to 443 times out | TCP/IP | Wrong address, host down, or a firewall dropping packets |
| `certificate verify failed` | TLS | Name mismatch, expired certificate, untrusted authority |
| `502 Bad Gateway` | Application | Edge reached a backend address that refuses or errors |
| `503 Service Unavailable` | Application | Health checks have marked every backend down |
| Only one `X-Backend` value | Application | One backend down or isolated; the edge routes around it |

Refused means a host answered with a TCP reset: it is reachable but nothing
listens on that port. A timeout means nothing answered: the host is down, the
address is wrong, or a firewall dropped the packets.
