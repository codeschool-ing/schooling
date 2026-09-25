---
title: One packet, two links
version: 1
---

Lesson 1 said a router builds a new frame for the next link. Here is one ping, captured on both sides
of the office router at the same moment: on the laptop's link, and on the router's link to the
provider.

```
ana@laptop:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.630 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.630/0.630/0.630/0.000 ms
```

On the office side:

```
ana@laptop:~$ sudo tcpdump -n -e -v -c 2 -i eth0 icmp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:09.168188 52:54:00:a8:0a:14 > 52:54:00:a8:0a:01, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 16622, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.0.2.80: ICMP echo request, id 60133, seq 1, length 64
13:16:09.168650 52:54:00:a8:0a:01 > 52:54:00:a8:0a:14, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 61, id 54088, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.80 > 192.168.10.20: ICMP echo reply, id 60133, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

On the provider side, a fraction of a millisecond later:

```
ana@router:~$ sudo tcpdump -n -e -v -c 2 -i eth1 icmp
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:09.168440 52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 16622, offset 0, flags [DF], proto ICMP (1), length 84)
    203.0.113.2 > 192.0.2.80: ICMP echo request, id 60133, seq 1, length 64
13:16:09.168646 52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 62, id 54088, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.80 > 203.0.113.2: ICMP echo reply, id 60133, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

`-v` adds the IP header's fields in brackets, and set side by side they show exactly what the router
did:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"One echo request captured on both sides of the office router. On the office LAN: MAC from 52:54:00:a8:0a:14 to 52:54:00:a8:0a:01, IP from 192.168.10.20 to 192.0.2.80, TTL 64, IP id 16622. On the ISP link: MAC from 52:54:00:00:71:02 to 52:54:00:00:71:01, IP from 203.0.113.2 to 192.0.2.80, TTL 63, IP id 16622. The MACs are new at every link, the source address was rewritten by NAT, the TTL is one less per router, and the unchanged id shows it is the same packet.\"><defs><marker id=\"hp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">before the router, on the office LAN</text><text x=\"420\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after the router, on the ISP link</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">MAC from → to</text><rect x=\"170\" y=\"46\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">52:54:00:a8:0a:14 → …:0a:01</text><rect x=\"420\" y=\"46\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">52:54:00:00:71:02 → …:71:01</text><text x=\"420\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new at every link</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">IP from → to</text><rect x=\"170\" y=\"98\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.20 → 192.0.2.80</text><rect x=\"420\" y=\"98\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.2 → 192.0.2.80</text><text x=\"420\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">source rewritten by NAT</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">TTL</text><rect x=\"170\" y=\"150\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">64</text><rect x=\"420\" y=\"150\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">63</text><text x=\"420\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">one less per router</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">IP id</text><rect x=\"170\" y=\"202\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16622</text><rect x=\"420\" y=\"202\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16622</text><text x=\"420\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the same packet</text></svg>", "caption": "What a router changes and what it keeps. The destination address and the id survive; the MACs, the TTL and, here, the source address do not."}
```

- **The MAC addresses are all new.** On the office link the frame went from the laptop to the router;
  on the provider link it goes from the router's other card, `52:54:00:00:71:02`, to the provider's
  router. Each link has its own pair.
- **The TTL went from 64 to 63**, the router's one subtraction. The reply shows the same from the
  other direction: 62 on the provider link, 61 by the time it reached the laptop.
- The IP `id` is **16622 on both sides**. It is the number the sender gave this packet, and it is the
  proof that this is one packet forwarded, not a new one.
- **The source address changed**, from `192.168.10.20` to `203.0.113.2`. A router does not normally do
  that. This one does, and the next section is why.
