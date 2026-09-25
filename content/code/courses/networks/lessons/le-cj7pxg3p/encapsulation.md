---
title: One packet, taken apart
version: 1
---

Each layer wraps what it receives from the layer above in a header of its own, and the layer below
treats the whole thing as data. That is **encapsulation**, and one packet shows it. The laptop
fetched `http://www.example.com/` while `tcpdump -XX` printed the frame carrying the request, byte by
byte:

```
ana@laptop:~$ sudo tcpdump -n -e -XX -c 1 "tcp dst port 80 and tcp[tcpflags] & tcp-push != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:05:57.717708 52:54:00:a8:0a:14 > 52:54:00:a8:0a:01, ethertype IPv4 (0x0800), length 144: 192.168.10.20.49864 > 192.0.2.80.80: Flags [P.], seq 365871663:365871741, ack 1424285085, win 63, options [nop,nop,TS val 915910785 ecr 3747846154], length 78: HTTP: GET / HTTP/1.1
        0x0000:  5254 00a8 0a01 5254 00a8 0a14 0800 4500  RT....RT......E.
        0x0010:  0082 9b9e 4000 4006 11cb c0a8 0a14 c000  ....@.@.........
        0x0020:  0250 c2c8 0050 15ce c22f 54e4 dd9d 8018  .P...P.../T.....
        0x0030:  003f 8d81 0000 0101 080a 3697 b081 df63  .?........6....c
        0x0040:  980a 4745 5420 2f20 4854 5450 2f31 2e31  ..GET./.HTTP/1.1
        0x0050:  0d0a 486f 7374 3a20 7777 772e 6578 616d  ..Host:.www.exam
        0x0060:  706c 652e 636f 6d0d 0a55 7365 722d 4167  ple.com..User-Ag
        0x0070:  656e 743a 2063 7572 6c2f 382e 352e 300d  ent:.curl/8.5.0.
        0x0080:  0a41 6363 6570 743a 202a 2f2a 0d0a 0d0a  .Accept:.*/*....
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

The first line is `tcpdump`'s summary, and the block below it is the frame itself: 144 bytes in
hexadecimal, 16 to a line, with the printable characters on the right. Cut at the layer boundaries,
it looks like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The 144-byte frame captured on the laptop, cut into its layers. The first 14 bytes are the Ethernet header: from the laptop&#x27;s MAC 52:54:00:a8:0a:14 to 52:54:00:a8:0a:01, which is the router&#x27;s, not the web server&#x27;s. The next 20 bytes are the IP header: from 192.168.10.20 to 192.0.2.80, TTL 64, carrying TCP. The next 32 bytes are the TCP header: port 49864 to port 80, flags P and ACK. The last 78 bytes are the HTTP request: GET / HTTP/1.1 with Host: www.example.com.\"><defs><marker id=\"fr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"66.11111111111111\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"53.05555555555556\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ethernet</text><rect x=\"86.11111111111111\" y=\"30\" width=\"94.44444444444444\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"133.33333333333334\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">IP</text><rect x=\"180.55555555555554\" y=\"30\" width=\"151.11111111111111\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.1111111111111\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TCP</text><rect x=\"331.66666666666663\" y=\"30\" width=\"368.3333333333333\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"515.8333333333333\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HTTP</text><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">144 bytes on the wire</text><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ethernet header, 14 bytes</text><text x=\"236\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:0a:14 → 52:54:00:a8:0a:01</text><text x=\"473.7\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to the router</text><rect x=\"20\" y=\"144\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">IP header, 20 bytes</text><text x=\"236\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.168.10.20 → 192.0.2.80</text><text x=\"406.6\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">TTL 64, carrying TCP</text><rect x=\"20\" y=\"176\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TCP header, 32 bytes</text><text x=\"236\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">49864 → 80</text><text x=\"309.0\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ports, flags P and ACK</text><rect x=\"20\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HTTP, 78 bytes</text><text x=\"236\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" xml:space=\"preserve\">GET / HTTP/1.1  Host: www.example.com</text></svg>", "caption": "One frame, four layers, each wrapped in the one below. The request itself is the last 78 bytes; everything before it is addressing."}
```

Three things can be read straight off the bytes:

- The frame starts with **`5254 00a8 0a01`, the destination MAC, and it is the router's**, not the
  web server's. The laptop sends everything outside the office to its gateway, the default route of
  section 04 at work. The IP destination, `c000 0250`, is `192.0.2.80`, the web server. Layer 2 says the next hop;
  layer 3 says the final destination.
- `0800` after the two MACs says "IPv4 follows". `45` starts the IP header: version 4, header 5 words
  of 4 bytes. `4006` a few bytes later is the TTL, `0x40` or 64, and the protocol, 6 for TCP.
- The request is readable from `GET` onwards, because HTTP on port 80 is not encrypted. Over HTTPS
  the same 78 bytes would be noise, which is lesson 5's point.
