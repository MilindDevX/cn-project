# Evidence index

## Integration recheck, 2026-09-29

The [live recheck](local/live-recheck-2026-09-29.txt) records DNS, trusted
HTTPS, direct backend status, A/B balancing, cache revalidation, and failure
tests involving both Macs, saved on Milind's Mac. The wrong team hostname
returned `NXDOMAIN`; forced wrong-IP and wrong-port HTTPS requests failed to
connect. Caddy briefly routed only to B, then passed repeated A/B checks
after restoration. See the
[proxy notes](../docs/proxy.md) for that unresolved intermittent route.

These are dated observations. Both Macs and their LAN addresses must be
checked again before the demo.

## Captured on Milind's Mac

| File | Shows |
| --- | --- |
| `local/live-recheck-2026-09-29.txt` | Dated end-to-end and failure recheck, including the intermittent route |
| `local/root.txt` | Root response and `X-Backend: A` |
| `local/status.txt` | JSON status and backend header |
| `local/status-lan.txt` | Backend reachable via this Mac's LAN IP |
| `local/cache-200.txt` | `Cache-Control: max-age=60` and ETag |
| `local/cache-304.txt` | Matching `If-None-Match` produces 304 |
| `local/backend-a.pcapng` | Wireshark capture on `lo0`: TCP SYN, SYN-ACK, GET `/api/status`, HTTP 200 |
| `local/pcap-summary.tsv` | Packet numbers and flags extracted from that capture |
| `local/wrong-port.txt` | Connection refused on unused port 3002; curl exit 7 |
| `local/dns-test-1053.txt` | Initial local UDP DNS test returned Aarohi's `10.7.23.42` on temporary port 1053, before the port-53 and second-Mac tests |
| `local/dns-team18-query.pcapng` | Wireshark capture of the temporary-port DNS query and A-record response on `lo0` |
| `local/dns-port53-direct.txt` | Direct query to dnsmasq on port 53 returned Aarohi's IP |
| `local/dns-port53-nslookup.txt` | Second DNS client returned Aarohi's IP |
| `local/dns-port53-system.txt` | Normal Wi-Fi DNS resolution returned Aarohi's IP |
| `local/dns-macos-resolver.txt` | macOS system resolver returned Aarohi's IP |
| `local/dns-wifi-setting.txt` | This Mac's Wi-Fi DNS server was `10.7.20.246` during the 2026-09-24 test; this setting has since been removed |
| `local/dns-aarohi-port53.pcapng` | Wireshark capture on `en0`: Aarohi's DNS query and matching A-record response |
| `local/dns-aarohi-summary.tsv` | Source, destination, and response value extracted from that capture |
| `local/dns-aarohi-system-app.pcapng` | Filtered Wireshark capture of Aarohi's later team-name query and response |
| `local/ca-trust.txt` | Verified public CA fingerprint and this Mac's SSL trust setting |
| `local/https-status.txt` | Successful TLS 1.3/HTTP/2 request, certificate verification, and Backend A status through Caddy |
| `local/https-cache-200.txt` | HTTPS cache response with `Cache-Control: max-age=60` and ETag |
| `local/https-cache-304.txt` | HTTPS conditional request with matching ETag returned `304` |
| `local/tls-proxy-a.pcapng` | Filtered Wireshark capture on `en0` of three HTTPS requests: TCP handshakes, TLS handshakes, and encrypted traffic |
| `local/dns-retest-team.txt` | After the forwarding fix, port-53 team-name lookup returned Aarohi's IP |
| `local/dns-retest-public.txt` | After the forwarding fix, port-53 public-name lookup succeeded |
| `local/dns-retest-wrong-name.txt` | Unknown team name returned `NXDOMAIN` |
| `local/dns-aarohi-retest.pcapng` | Four Wireshark packets on `en0`: Aarohi's team/public DNS queries and replies after the forwarding fix |
| `local/dns-aarohi-retest-summary.tsv` | Packet-level names, addresses, and A-record answers from the retest capture |
| `local/https-system-dns-status.txt` | Successful curl request through normal macOS DNS and certificate trust, without `--resolve` |
| `local/browser-certificate-valid.jpg` | Chrome shows `Connection is secure` and `Certificate is valid` |
| `local/browser-status-headers.jpg` | Chrome DevTools shows HTTPS `200`, Caddy, and `X-Backend: A` |
| `local/browser-cache-headers.jpg` | Chrome DevTools shows cacheable `200`, `Cache-Control: max-age=60`, and ETag |
| `local/browser-cache-304.jpg` | Chrome reload sends `If-None-Match` and receives `304 Not Modified` |
| `local/proxy-wrong-port.txt` | Curl to unused proxy port 8443 was refused |
| `local/proxy-wrong-port.pcapng` | Wireshark shows SYN then RST/ACK for the unused proxy port |
| `local/dns-wrong-ip-simulation.txt` | Isolated dnsmasq on port 1053 returned the deliberately wrong `127.0.0.1`; live DNS was unchanged |
| `local/https-wrong-ip-simulation.txt` | HTTPS to that wrong loopback IP was refused; curl exit 7 |
| `local/https-balancing.txt` | Eight HTTPS status responses alternated `X-Backend: A` and `B` through Caddy |
| `local/https-a-down.txt` | With A stopped, four HTTPS requests returned `200` from B |
| `local/https-both-down.txt` | With A and B stopped, Caddy returned `503` |
| `local/https-balanced-cache-200.txt` | Cacheable HTTPS `200` with Backend B's ETag |
| `local/https-balanced-cache-conditional.txt` | Conditional HTTPS requests with B's ETag: B returned `304`; A returned `200` with its own representation and ETag |
| `local/dns-aarohi-nslookup.txt` | Aarohi's Mac queried Milind's port-53 DNS server and received `10.7.23.42` |
| `local/https-normal-dns-balancing.txt` | Normal macOS DNS and trusted HTTPS reached Backend B without `--resolve` after dnsmasq restarted |
| `local/dns-aarohi-scoped.txt` | Aarohi's macOS scoped resolver uses Milind's DNS and normal host resolution returns `10.7.23.42` |
| `local/https-aarohi-normal-dns.txt` | Aarohi's normal HTTPS request reached Backend A without `--resolve` or `-k` |

The Backend A loopback TCP capture is plain HTTP, so it is **not** TLS or encrypted-traffic evidence. DNS and HTTPS on `en0`, plus Chrome security and DevTools screenshots, are captured above.

The DNS retest captures show dnsmasq responding on port 53 after the forwarding fix. Milind's manual Wi-Fi DNS setting remains removed after an earlier internet-access issue. A domain-specific macOS resolver routes `team18.test` to dnsmasq; `https-system-dns-status.txt` and the Chrome screenshots demonstrate normal system resolution. The earlier HTTPS capture used curl's `--resolve` option to isolate TLS testing before that resolver existed.

The 2026-09-29 A/B and failure captures used `--resolve` while dnsmasq was stopped. After restarting dnsmasq, both Macs used scoped resolvers for `team18.test`; `https-normal-dns-balancing.txt` and `https-aarohi-normal-dns.txt` show normal trusted HTTPS without `--resolve`. The earlier two-Mac `dig` and DNS packet captures are listed above.
