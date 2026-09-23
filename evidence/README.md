# Evidence index

## Captured on Milind's Mac

| File | Shows |
| --- | --- |
| `local/root.txt` | Root response and `X-Backend: A` |
| `local/status.txt` | JSON status and backend header |
| `local/status-lan.txt` | Backend reachable via this Mac's LAN IP |
| `local/cache-200.txt` | `Cache-Control: max-age=60` and ETag |
| `local/cache-304.txt` | Matching `If-None-Match` produces 304 |
| `local/backend-a.pcapng` | Wireshark capture on `lo0`: TCP SYN, SYN-ACK, GET `/api/status`, HTTP 200 |
| `local/pcap-summary.tsv` | Packet numbers and flags extracted from that capture |
| `local/wrong-port.txt` | Connection refused on unused port 3002; curl exit 7 |

The local capture is plain HTTP, so it is **not** TLS or encrypted-traffic evidence. Capture DNS and HTTPS on `en0` once the two-Mac setup is live. Save `.pcapng` files and curl outputs, plus screenshots of browser DevTools Headers/Network panels.

## Still needed from two-Mac integration

- `dig` and `nslookup` from both Macs using Milind's DNS server.
- Wireshark DNS query and reply on `en0`.
- TCP handshake to Aarohi's proxy, TLS handshake, and subsequent encrypted application packets.
- Browser certificate/security panel and `curl -v` with successful certificate verification.
- Repeated responses showing `X-Backend: A` and `X-Backend: B` through the proxy.
- Browser cache behavior and conditional `304` through the proxy.
- Wrong DNS name/IP, one backend down, both down, and proxy wrong-port captures.
