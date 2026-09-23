# DNS setup and verification — Milind's Mac

## Current LAN snapshot

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

Homebrew `dnsmasq 2.93` is installed. Configuration and service startup await Aarohi's Mac IPv4 address. The team 18 A record is `app.team18.test` → Aarohi's LAN IPv4.

When Aarohi's IP is known:

1. Configure dnsmasq to answer the exact hostname with Aarohi's IP and listen on this Mac's reachable LAN address on UDP/TCP port 53. Leave upstream DNS forwarding enabled for other names.
2. Set both Macs' Wi-Fi DNS server to this Mac's current LAN IP. Confirm that firewall and Wi-Fi client isolation permit UDP/TCP 53 from Aarohi's Mac.
3. Check `dig @<this-Mac-IP> app.team18.test A` on both Macs. Check `nslookup app.team18.test <this-Mac-IP>` as a second client. The answer must be Aarohi's current IP. Save command output and a Wireshark DNS query/response capture.
4. Check normal resolution without `@server` on both Macs. This proves the OS DNS setting is actually used. Use `dig`/`nslookup` with explicit server only to prove dnsmasq itself works.

Do not put this hostname in `/etc/hosts`; it would bypass the DNS query this project must demonstrate. Recheck LAN IPs after reconnecting to Wi-Fi.

## CA and HTTPS

Obtain the CA certificate and its SHA-256 fingerprint directly from Aarohi. Verify the fingerprint before adding that CA to macOS trust. Record `curl -v https://app.team18.test/` without `-k`, plus browser security details and a TLS capture. The TLS handshake and encrypted application data are between client and Aarohi's HTTPS proxy; Backend A receives HTTP on port 3001.

## Failure cases

| Case | Action | Evidence to save |
| --- | --- | --- |
| Wrong DNS name | Query a different `.test` name | NXDOMAIN or nonmatching answer; preserve resolver output |
| Wrong DNS IP | Temporarily set the test hostname's A record to an unused LAN IP | DNS returns the wrong IP, then HTTPS fails; restore the correct record immediately |
| One backend down | Stop A or B while proxy stays up | Proxy response/status and remaining backend identity |
| Both down | Stop both backends while proxy stays up | Proxy error/status and timestamp |
| Wrong port | Point a test request or proxy upstream to an unused port | Connection failure or proxy error; local request example in `evidence/local/wrong-port.txt` |

Run shared cases only after the proxy and both backends are connected. Record expected behavior from the proxy configuration before judging results.
