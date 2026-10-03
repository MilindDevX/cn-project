# Team 18 submission checklist

This checklist covers the requirements recorded for this project. The actual
submission form, deadline, and enrollment fields have not been supplied;
confirm those from the course instructions.

## Before recording

- [ ] Confirm both current DHCP addresses and update deployed configs if needed.
- [ ] Confirm Backend A on 3001, Backend B on 3002, and Caddy on 443.
- [ ] Verify both Macs can query Milind's DNS server on port 53.
- [ ] Verify normal DNS and trusted HTTPS without `--resolve` or `-k`.
- [ ] Recheck responses from A and B and cache `200`/`304` behavior.
- [ ] Capture the required terminal, browser, and Wireshark views for the video.

## Required demonstrations

- [ ] DNS query and A-record response from the second Mac.
- [ ] TCP three-way handshake, TLS handshake, and encrypted records.
- [ ] Browser/curl certificate trust and `X-Backend` headers.
- [ ] A/B balancing and `Cache-Control: max-age=60` with ETag/`304`.
- [ ] Wrong hostname, wrong IP, wrong port, A down, and both backends down.
- [ ] Both backends restored after failure testing.

Use [demo commands](demo-commands.md) to produce the required views.

## Video and delivery

- [ ] Five-minute video with approximately 2:30 each for Milind and Isha.
- [ ] Readable terminal/browser/Wireshark text and audible narration.
- [ ] Correct speaker labels and dates on recorded demonstrations.
- [ ] Required repository and video links open for the intended assessor.
- [ ] No private keys, credentials, unrelated personal screens, or private notes.
- [ ] Confirm any additional requirements in the actual submission form.

Publishing, committing, or pushing the prepared work requires Milind's
approval. See the [video script](phase1-video-script.md) and
[demo commands](demo-commands.md).
