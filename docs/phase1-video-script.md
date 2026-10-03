# Five-minute Team 18 video

Milind and Isha each have **2 minutes 30 seconds**. The time slots include
brief pauses to point out results on screen. Rehearse at a natural pace and
adjust pauses to the allocated slots.

Record the required terminal, browser, and Wireshark views separately.
Isha's address and services need confirmation before a live demonstration.
See [demo commands](demo-commands.md).

## 0:00–0:45 — Milind: request path and Backend A

**Screen:** Architecture diagram, then A's root and status responses.

“Hi, we're Team 18. Our project connects two Macs through DNS, HTTPS, and
a load-balancing proxy. My Mac runs Backend A on port 3001. Its root endpoint
says ‘Hello from Backend A’, and its status endpoint returns a JSON response
with backend A. Every response also carries the X-Backend A header. In this
diagram, a client first asks my DNS server for the project address. It then
connects to Isha's HTTPS proxy, which sends the request to one of our two
backends.”

## 0:45–1:30 — Isha: Backend B and Caddy

**Screen:** Backend B status, then `phase1/configs/Caddyfile`.

“My Mac runs Backend B on port 3002 and Caddy on port 443. Backend B has the
same routes as A, but identifies itself as B. The Caddyfile sends traffic to
Backend A on Milind's Mac or Backend B on mine. It uses round-robin selection
and checks each backend's status endpoint every two seconds. Caddy also
handles the HTTPS certificate. The certificate files stay on my Mac; the
repository contains the configuration, but not the private key.”

## 1:30–2:15 — Milind: DNS

**Screen:** dnsmasq config, `dig`, Isha's `nslookup`, and DNS capture.

“My dnsmasq server maps app dot team18 dot test to Isha's recorded IP address,
10.7.23.42. During our integration test, both Macs used a resolver for the
project domain while their normal Wi-Fi DNS settings stayed automatic. This
dig result shows the team address. Isha's nslookup shows that her Mac queried
my DNS server. In Wireshark, we can see her DNS request and the reply. We also
checked that the server could forward a public-domain query.”

## 2:15–3:00 — Isha: trusted HTTPS, TCP, and TLS

**Screen:** Certificate screenshot, HTTPS output, TLS packet capture.

“Next, the client opens our HTTPS hostname. Chrome shows a valid certificate,
and curl verified the connection without bypassing certificate checks. This
Wireshark capture starts with the TCP handshake, followed by the TLS
ClientHello and ServerHello. The later application packets are encrypted,
so their HTTP contents are not readable in this capture. Caddy ends the TLS
connection and forwards HTTP to the selected backend. The response still
tells us which backend handled it through X-Backend.”

## 3:00–3:45 — Milind: headers and caching

**Screen:** DevTools status and cache headers, then browser `304` screenshot.

“Here, DevTools shows an HTTPS 200 response and the backend header. Our cache
endpoint sends Cache-Control with max-age 60 and an ETag. The client can send
that ETag back using If-None-Match. When it matches the selected backend's
version, the response is 304 Not Modified. This screenshot shows the
conditional request and its 304 result. The two backends have different
ETags, so a request routed to the other backend can correctly return its own
200 representation.”

## 3:45–4:30 — Isha: balancing and A down

**Screen:** Alternating A/B outputs, then A-down result.

“To check balancing, we sent repeated requests through Caddy and recorded
responses from both A and B. After restoring the services, twelve requests
spaced five seconds apart alternated between the two backends. We also
tested failure handling. With Backend A stopped, the proxy still returned
successful responses from Backend B. That test shows the site can continue
serving requests when one backend is unavailable. These are recorded results,
so we'll repeat the IP and balancing checks before the final demo.”

## 4:30–4:45 — Milind: wrong name, IP, and port

**Screen:** Three failure outputs with clear labels.

“We tested three client-side mistakes: an unknown DNS name returned NXDOMAIN;
an isolated wrong-IP test failed to connect; and port 8443 was refused.”

## 4:45–5:00 — Isha: both down and wrap-up

**Screen:** Both-down `503`, then repository README.

“With both backends stopped, Caddy returned 503. We restored both afterward.
Our backend code, configuration, and setup guides are organized in this
repository. That completes our Team 18 network demonstration.”
