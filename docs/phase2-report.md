# Phase 2 report

All tests ran on 19 November 2026 on the two Macs: Milind's at `10.7.31.154`
(primary DNS, Backend A, standby edge) and Isha's at `10.7.3.96` (backup DNS,
primary edge, Backend B). The raw output of every test is in
[`evidence/phase2/`](../evidence/phase2). Commands are in the
[Phase 2 guide](phase2.md).

## What changed from Phase 1

| Area | Phase 1 | Phase 2 |
| --- | --- | --- |
| DNS servers | One dnsmasq on Milind's Mac | A second dnsmasq on Isha's Mac with the same record; clients list both |
| DNS record | `host-record` in the config, default TTL | Hosts file read with `addn-hosts`, 30-second TTL, reloaded with `SIGHUP` |
| Backend ports | Open to the whole LAN | pf rules: only the edge reaches 3001; only loopback reaches 3002 |
| Edge health checks | Active checks every 2 s | Active checks with a 1 s timeout, plus passive checks that mark a failing backend down for 10 s |
| Edges | One Caddy on Isha's Mac | A standby Caddy on Milind's Mac; both add an `X-Edge` header |
| Configs | Fixed IP addresses | Templates rendered for the day's DHCP addresses |
| Diagnosis | Manual commands | `phase2/scripts/diagnose.sh` checks DNS, IP, TCP, TLS and HTTP in order |

## Results

### A. Backup DNS resolver

Both servers returned `app.team18.test 30 IN A 10.7.3.96`, and each client's
resolver listed `10.7.31.154` first and `10.7.3.96` second
([before](../evidence/phase2/A-before.txt)). With dnsmasq stopped on Milind's
Mac ([log](../evidence/phase2/A-primary-stopped.txt)):

- `dig @10.7.31.154` timed out: no servers could be reached.
- `dig @10.7.3.96` still answered `10.7.3.96`.
- After the 30-second TTL expired, the system resolver still returned
  `10.7.3.96`, answered by the backup.
- `https://app.team18.test/api/status` returned `200` from Backend B.

After the primary restarted, it answered again
([log](../evidence/phase2/A-after.txt)).

### B. TTL and controlled record change

Every answer carried `TTL 30`. The record was changed from the primary edge
(`10.7.3.96`) to the standby (`10.7.31.154`) while a client logged its cached
answer, the server's answer and the edge serving it every 3 seconds
([log](../evidence/phase2/BE-cutover-watch.txt)):

| Time | Client cache | Server answer | Edge serving |
| --- | --- | --- | --- |
| 15:30:53 | 10.7.3.96 | 10.7.3.96 | primary |
| 15:30:56 | 10.7.3.96 | **10.7.31.154** | primary |
| 15:31:25 | 10.7.3.96 | 10.7.31.154 | primary |
| 15:31:28 | **10.7.31.154** | 10.7.31.154 | **standby** |

The client kept the old answer for 32 seconds, one TTL plus the logging
interval. In a second run the record was switched back and the cache flushed
by hand ([log](../evidence/phase2/B-flush-watch.txt)): the client held the old
answer for 5 seconds after the change, then moved to the new one in the same
second as `dscacheutil -flushcache` and `killall -HUP mDNSResponder`.

### C. Service isolation (Backend A side)

With the rule loaded on Milind's Mac ([log](../evidence/phase2/C-isolation.txt)):

- From Isha's Mac (the edge), `http://10.7.31.154:3001/api/status` returned `200`.
- From a phone on the same Wi-Fi, the same URL timed out ("took too long to respond").
- The live rules showed 364 packets passed from the edge and 70 packets dropped
  by the block rule.
- After the rollback (`pfctl -a com.apple/team18 -F all`, then `pfctl -X` with
  the enable token), the anchor listed no rules and pf returned to disabled.

### C. Service isolation (Backend B side)

With the rule loaded on Isha's Mac, Milind's Mac probed port 3002 every few
seconds ([probe log](../evidence/phase2/C-isha-probe.txt),
[live rules](../evidence/phase2/C-isha-live-rules.txt)):

- Before the rule, and again after the rollback, every probe returned `200`.
- While the rule was on (16:03:55 to 16:04:16), every probe timed out.
- In the first run with both rules on, Caddy still reached Backend B at
  `127.0.0.1:3002` over loopback, and requests through the edge returned both
  `x-backend: A` and `B` ([log](../evidence/phase2/C-isolation.txt)).
- The block rule counted 88 dropped packets. After the rollback the anchor
  listed no rules and pf returned to disabled.

### D. High-availability failover

Through the primary edge ([log](../evidence/phase2/D-failover.txt)):

| State | Six requests |
| --- | --- |
| Both backends running | A, B, A, B, A, B, all `200` |
| Backend A stopped (direct connection refused) | B six times, all `200`, sent immediately |
| Backend A restarted | A, B, A, B, A, B, all `200` |

No request failed when A stopped: the failed attempt marked A down (passive
check) and `lb_try_duration` retried on B. When both backends were stopped in
an earlier local test, Caddy returned `503`.

The edge on Isha's Mac is still a single point of failure. If Caddy or that Mac
stops, nothing serves `app.team18.test`. Removing it needs two edges sharing
one address (a floating IP with VRRP, for example keepalived), or DNS that
returns several edges and stops returning a failed one.

### E. Controlled edge migration

The cutover in Extension B moved traffic from the primary edge to the standby
edge. Both edges kept serving during the change, so no request failed: cached
clients reached the primary edge until 15:31:25, and from 15:31:28 every
request reached the standby (`x-edge: standby`), which balanced across both
backends.

## Troubleshooting findings

| Finding | Layer | Cause and fix |
| --- | --- | --- |
| Every Phase 1 config pointed at the wrong DNS server | IP | DHCP had moved Milind's Mac from `10.7.20.246` to `10.7.31.154` and Isha's to `10.7.3.96`. Configs became templates rendered for each day's addresses. |
| `dig app.team18.test` without `@server` gave no answer | DNS | `dig` ignores `/etc/resolver`. The scoped resolver is tested with `dscacheutil`, curl or a browser; `dig` needs `@server`. |
| `dscacheutil` hung instead of failing | DNS | It waits when every listed server is down. The diagnosis script gives it 5 seconds. |
| The first query to the backup DNS got no reply | DNS | Isha's macOS application firewall was prompting for dnsmasq. Once dnsmasq was allowed, queries were answered. |
| A blocked port and a stopped backend looked alike | TCP | With `block drop`, a blocked client times out; a stopped backend sends a reset (`connection refused`) at once. |
| The edge's `X-Backend` header seemed missing | HTTP | HTTP/2 sends header names in lower case (`x-backend`). Header checks must ignore case. |

## Learning summary

**A. Backup DNS.** A DNS failure and an application failure look different
from the client. When DNS fails, the name does not resolve and no connection
is even attempted, although every server may be healthy. When the application
fails, the name resolves and TCP may connect, but the service returns an error
or refuses the connection. A second resolver removes DNS as a single point of
failure; the client tries the next listed server after a timeout.

**B. TTL and record change.** The TTL is how long a resolver may reuse an
answer without asking again. The server changed at once, but the client
followed only when its cached answer expired, about 30 seconds later. This is
why a production migration lowers the TTL well before the change, keeps the
old server running for at least one old TTL afterwards, and only then removes
it. Flushing the cache helps on a machine you control, but never on users'
machines.

**C. Service isolation.** Only the edge needs to reach the backends, so
everything else is refused at the network layer. The rules go into a pf anchor
that the stock `/etc/pf.conf` already evaluates, which makes the rollback
exact: flush the anchor and release the enable token. Dropping packets rather
than refusing them hides whether a service exists, and the resulting timeout
is itself a clue when diagnosing a fault.
**C. Isolation on the edge's own Mac.** Backend B shares a Mac with the edge,
so it needs no LAN access at all: allowing loopback and dropping everything
else on port 3002 is enough, and it shows that the edge is the only way in.

**D. Failover.** Active health checks find a dead backend within one interval;
passive checks react to the first failed request; retries hide the failure from
the client. Together they removed every client-visible error when Backend A
stopped. Redundant backends do not make the service highly available while the
edge itself has no backup.


**E. Edge migration.** DNS moves traffic gradually, not at a single instant,
because each client switches when its own cached answer expires. Both edges
must therefore serve correctly during the change, and the TTL sets how long
the overlap lasts.
