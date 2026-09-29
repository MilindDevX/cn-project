# DNS setup and verification — Milind's Mac

## Recorded LAN snapshot

Captured 2026-09-23 18:56 IST. These DHCP and private Wi-Fi MAC values may change when the network changes.

| Item | Value |
| --- | --- |
| Interface | `en0` (Wi-Fi) |
| IPv4 | `10.7.20.246` |
| Subnet mask | `255.255.224.0` (`/19`) |
| Network | `10.7.0.0/19` |
| Gateway | `10.7.0.1` |
| MAC | `32:f4:e3:a0:0f:ef` |

Source: `ifconfig en0` and `netstat -rn -f inet` on this Mac. Record fresh values before the demo.

## DNS server

Homebrew `dnsmasq 2.93` is installed. [`dnsmasq/team18.conf`](../dnsmasq/team18.conf) maps `app.team18.test` to Isha's `10.7.23.42`, binding this Mac's `127.0.0.1` and `10.7.20.246`. The same config is installed at `/opt/homebrew/etc/dnsmasq.d/team18.conf`. During the 2026-09-24 test, direct `dig`, `nslookup`, and normal macOS resolution on both Macs returned the intended A record. A Wireshark capture on Milind's `en0` shows Isha's query and the response. On 2026-09-29, dnsmasq served port 53 and its syntax check passed. A later inspection found `system/sh.brew.dnsmasq` running from `/Library/LaunchDaemons/sh.brew.dnsmasq.plist`, with `RunAtLoad` and `KeepAlive` enabled. `brew services list` still reported `none`, so inspect launchd directly if its status is uncertain. Actual restart after a reboot was not tested.

Milind reported losing internet access while using this Mac for Wi-Fi DNS, then stopped dnsmasq and restored automatic DNS. A controlled test showed the earlier config could not forward public names when its resolver file pointed back to this Mac. The current config uses `no-resolv` with the verified upstream `8.8.8.8`; a port-1053 test resolved both `www.example.org` and `app.team18.test` under that same condition. The original outage's exact sequence was not captured. On 2026-09-24, dnsmasq was restarted on port 53. Both Macs resolved `app.team18.test` to `10.7.23.42` and `example.com` to public addresses through `10.7.20.246`; a fresh Wireshark capture on Milind's `en0` contains both queries from Isha and their responses. Milind's `/etc/resolver/team18.test` routes only the project domain to `10.7.20.246`; Wi-Fi DNS remains automatic for other names. macOS host resolution, ordinary curl to the project hostname, Chrome, and public HTTPS were verified after this change. On 2026-09-29, Milind restarted dnsmasq; direct team and public queries succeeded from both Macs, Isha's `nslookup` returned the team IP, and ordinary HTTPS on Milind's Mac reached Backend B without `--resolve`.

The domain-specific resolver file contains:

```text
nameserver 10.7.20.246
```

On 2026-09-29, Isha installed the same `/etc/resolver/team18.test` setting while keeping Wi-Fi DNS automatic. Her `scutil --dns` showed `10.7.20.246` for `team18.test`, normal macOS host resolution returned `10.7.23.42`, and curl reached Backend A over trusted HTTPS without `--resolve`. Her direct `dig` and `nslookup` also queried Milind's DNS server successfully.

Before each demo:

1. Recheck both Macs' DHCP addresses against the config file.
2. If dnsmasq is stopped, start it on Milind's Mac with `sudo /opt/homebrew/bin/brew services start dnsmasq`; enter the administrator password only in the Mac's Terminal. Run `dig @10.7.20.246 app.team18.test A` and `dig @10.7.20.246 example.com A` to check the project record and public forwarding. Keep both Macs' Wi-Fi DNS settings automatic.
3. Repeat `nslookup app.team18.test 10.7.20.246` from Isha's Mac; the 2026-09-29 output is saved in [the evidence folder](../evidence/local/dns-isha-nslookup.txt). The domain-specific resolver routes browser requests for `team18.test` to dnsmasq without changing public-name DNS.

Do not put this hostname in `/etc/hosts`; it would bypass the DNS query this project must demonstrate. Recheck LAN IPs after reconnecting to Wi-Fi.

## CA and HTTPS

Isha's public mkcert CA matched the supplied SHA-256 fingerprint and is trusted for SSL in Milind's login keychain. On 2026-09-24, curl connected to Isha's Caddy proxy both with `--resolve app.team18.test:443:10.7.23.42` and later through normal macOS domain resolution. It verified the certificate for `app.team18.test` without `-k`, negotiated TLS 1.3 and HTTP/2, and received Backend A's `200` status response. The Wireshark capture shows the TCP handshake, TLS ClientHello and ServerHello, and encrypted application records. Chrome showed a secure connection and DevTools recorded Backend A headers, a cacheable `200`, and an `If-None-Match` reload returning `304`. The TLS connection is between Milind's Mac and Isha's proxy; Backend A receives HTTP on port 3001.

## Failure cases

| Case | Action | Evidence to save |
| --- | --- | --- |
| Wrong DNS name | Query a different `.test` name | NXDOMAIN or nonmatching answer; preserve resolver output |
| Wrong DNS IP | Run an isolated dnsmasq on port 1053 with `app.team18.test` mapped to `127.0.0.1`; make one HTTPS request using that test answer | The test server returned `127.0.0.1` and local HTTPS port 443 refused the connection; live port-53 DNS stayed correct |
| One backend down | Stop A while proxy stays up | Four HTTPS requests returned `200`, `X-Backend: B`; `evidence/local/https-a-down.txt` |
| Both down | Stop A and B while proxy stays up | HTTPS returned `503`; `evidence/local/https-both-down.txt` |
| Wrong port | Request the proxy on unused port 8443 | Curl connection refusal and Wireshark SYN followed by RST/ACK; local backend request example also in `evidence/local/wrong-port.txt` |

Both backends were restored after the 2026-09-29 tests; four follow-up requests alternated A/B. The recorded HTTPS failure tests used curl's `--resolve` to isolate proxy behavior from DNS, which was stopped at the time. Dnsmasq was then restarted and an ordinary HTTPS request succeeded without `--resolve`. Recheck both Macs' LAN addresses before the demo.
