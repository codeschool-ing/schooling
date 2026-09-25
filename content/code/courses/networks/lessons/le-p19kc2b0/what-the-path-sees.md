---
title: What the path can see
version: 1
---

The office router is where the internet provider's view begins, so it is the place to test the
promise. First the price list over plain HTTP, recorded to a file and then searched:

```
ana@router:~$ sudo timeout 3 tcpdump -n -i eth1 -w /tmp/http.pcap tcp port 80
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
10 packets received by filter
0 packets dropped by kernel
ana@router:~$ tcpdump -n -A -r /tmp/http.pcap 2>/dev/null | grep -E "GET|Host:|Location:"
13:57:47.491853 IP 203.0.113.2.45042 > 192.0.2.80.80: Flags [P.], seq 1:89, ack 1, win 63, options [nop,nop,TS val 2471684949 ecr 4226938385], length 88: HTTP: GET /prices.txt HTTP/1.1
.R.U....GET /prices.txt HTTP/1.1
Host: www.example.com
Location: https://www.example.com/prices.txt
```

The router read **the request, `GET /prices.txt`, the site, `Host: www.example.com`, and the
answer's `Location:`**. Had the server answered with the file, the file would have been there too.
Now the same fetch over HTTPS:

```
ana@router:~$ sudo timeout 3 tcpdump -n -i eth1 -w /tmp/https.pcap tcp port 443
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
36 packets captured
36 packets received by filter
0 packets dropped by kernel
ana@router:~$ tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -c -E "GET|prices|line 1 of"
0
ana@router:~$ tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -o -m 1 "www.example.com"
www.example.com
```

36 packets, and **not one contains `GET`, `prices` or the first line of the file**. What the router
could still read is the name: `www.example.com` travels in the clear in the Client hello, because the
server needs it before any key exists.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"What the office router could read. For plain HTTP: the addresses and ports, yes; the name, yes, in the Host header; the path, /prices.txt, yes; the page itself, yes; and nobody could tell if it had been changed on the way. For HTTPS: the addresses and ports, yes; the name, yes, in the ClientHello; the path, no; the page, no; and any change on the way would break the connection.\"><defs><marker id=\"ob-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what the router saw</text><text x=\"330\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">http://</text><text x=\"520\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">https://</text><rect x=\"14\" y=\"38\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the addresses and ports</text><text x=\"330\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><text x=\"520\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><rect x=\"14\" y=\"74\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the name, www.example.com</text><text x=\"330\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes, in Host:</text><text x=\"520\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes, in the ClientHello</text><rect x=\"14\" y=\"110\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the path, /prices.txt</text><text x=\"330\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"520\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no</text><rect x=\"14\" y=\"146\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the page itself</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"520\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no</text><rect x=\"14\" y=\"182\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">whether it was changed on the way</text><text x=\"330\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cannot tell</text><text x=\"520\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes: it would break</text></svg>", "caption": "HTTPS hides what you asked for and what came back, and makes tampering fail loudly. It does not hide who you talked to."}
```

So HTTPS protects what you asked for and what came back, and it makes tampering break the connection
instead of silently succeeding. **It does not hide which site you visited**: the addresses, and in most
connections the name, are visible to the office network, the provider and anybody between. A company
proxy or a school filter that blocks sites by name works exactly from that.
