---
title: "Four messages: discover, offer, request, acknowledge"
version: 1
---

A PC with no address gets one in four messages, known by their initials as **DORA**: *discover*,
*offer*, *request*, *acknowledge*. The client cannot address the server, because it knows neither
the server's address nor its own, so it starts by asking everybody. The conversation runs over UDP,
from port 68 on the client to port 67 on the server.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The four DHCP messages between pc1, the client, and srv, the DHCP server, as srv's tcpdump printed them. One: DHCPDISCOVER from 0.0.0.0 port 68 to 255.255.255.255 port 67, a broadcast asking for any server. Two: DHCPOFFER from 10.20.10.10 port 67 to 10.20.10.100 port 68, an offer sent to pc1's hardware address. Three: DHCPREQUEST, again from 0.0.0.0 to 255.255.255.255, a broadcast saying which offer is taken. Four: DHCPACK from 10.20.10.10 to 10.20.10.100, the confirmation with the options. Afterwards pc1 has 10.20.10.100/24, a default route and a name server.\"><defs><marker id=\"dd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"105\" y=\"12\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"190\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client</text><line x1=\"190\" y1=\"56\" x2=\"190\" y2=\"276\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></line><rect x=\"445\" y=\"12\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv  10.20.10.10</text><text x=\"530\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">server</text><line x1=\"530\" y1=\"56\" x2=\"530\" y2=\"276\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></line><line x1=\"192\" y1=\"92\" x2=\"526\" y2=\"92\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPDISCOVER</text><text x=\"360\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0.68 &gt; 255.255.255.255.67</text><text x=\"14\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"546\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broadcast: any server?</text><line x1=\"528\" y1=\"144\" x2=\"194\" y2=\"144\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPOFFER</text><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10.67 &gt; 10.20.10.100.68</text><text x=\"14\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"546\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an offer, to pc1's MAC</text><line x1=\"192\" y1=\"196\" x2=\"526\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPREQUEST</text><text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0.68 &gt; 255.255.255.255.67</text><text x=\"14\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"546\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broadcast: I take that one</text><line x1=\"528\" y1=\"248\" x2=\"194\" y2=\"248\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPACK</text><text x=\"360\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10.67 &gt; 10.20.10.100.68</text><text x=\"14\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"546\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confirmed, with options</text><text x=\"360\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pc1 binds 10.20.10.100/24, a default route and a name server</text></svg>", "caption": "DORA as srv's tcpdump saw it: the client's two messages are broadcasts from 0.0.0.0, and the server's two go to the address being offered."}
```

Here is pc1 asking, with ISC's client, `dhclient`, and `-v` so that it prints every step:

```
ana@pc1:~$ sudo dhclient -v eth0
Internet Systems Consortium DHCP Client 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

Listening on LPF/eth0/02:25:70:bc:29:c6
Sending on   LPF/eth0/02:25:70:bc:29:c6
Sending on   Socket/fallback
xid: warning: no netdev with useable HWADDR found for seed's uniqueness enforcement
xid: rand init seed (0x6ac49ffe) built using gethostid
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xe264ec04)
DHCPOFFER of 10.20.10.100 from 10.20.10.10
DHCPREQUEST for 10.20.10.100 on eth0 to 255.255.255.255 port 67 (xid=0x4ec64e2)
DHCPACK of 10.20.10.100 from 10.20.10.10 (xid=0xe264ec04)
bound to 10.20.10.100 -- renewal in 291 seconds.
```

The banner and the two `xid:` lines are the client starting up and seeding the random transaction
number it uses to recognise the replies meant for it. Then the four lines that matter:

- `DHCPDISCOVER on eth0 to 255.255.255.255 port 67`: to the broadcast address, so every machine on
  the subnet receives it.
- `DHCPOFFER of 10.20.10.100 from 10.20.10.10`: a server proposes an address.
- `DHCPREQUEST for 10.20.10.100 on eth0 to 255.255.255.255`: the client asks for that address,
  again to everybody.
- `DHCPACK of 10.20.10.100 from 10.20.10.10`: the server confirms, and the client binds the
  address, `bound to 10.20.10.100 -- renewal in 291 seconds`.

**The request goes to everybody even though the client already knows which server answered.** If
two servers made offers, the request names the one chosen, and the broadcast tells the others to put
their addresses back. The transaction number ties the four together: the DISCOVER and the ACK both
carry `xid=0xe264ec04`. The REQUEST line prints `0x4ec64e2`, which is the same four bytes in the
opposite order (`e2 64 ec 04` against `04 ec 64 e2`), a quirk of how this client prints that one
line.

Meanwhile, on srv, a `tcpdump` started in a second terminal printed the four packets as the server
saw them. It is shown after pc1's command because it printed when it ended:

```
root@srv:~# timeout 15 tcpdump -n -i eth0 -c 4 port 67 or port 68
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:20:31.505285 IP 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 02:25:70:bc:29:c6, length 300
08:20:32.541960 IP 10.20.10.10.67 > 10.20.10.100.68: BOOTP/DHCP, Reply, length 300
08:20:32.552098 IP 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 02:25:70:bc:29:c6, length 300
08:20:32.558801 IP 10.20.10.10.67 > 10.20.10.100.68: BOOTP/DHCP, Reply, length 300
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

The client's two messages leave from `0.0.0.0.68`: **an address of all zeros, because the client
has none yet**, to `255.255.255.255.67`. The server's two replies go to `10.20.10.100.68`, the
address being offered, which pc1 does not hold yet. The server cannot ask ARP who has an address
nobody has, so it sends the frame to the hardware address the request carried: `Request from
02:25:70:bc:29:c6` is in both requests for exactly that reason.

When the ACK had arrived, pc1 looked like this:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if123       UP             10.20.10.100/24 fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.100 
ana@pc1:~$ cat /etc/resolv.conf
nameserver 10.20.10.10
```

Three things came in that exchange, not one. The address, `10.20.10.100/24`, and with its mask the
route to its own subnet. A default route via 10.20.10.1, the router. And a name server, 10.20.10.10,
written into `/etc/resolv.conf`. **DHCP delivers a whole configuration, and the address is only the
first line of it.** Each item beyond the address is an *option* in the reply, and the server's file
decides which options are sent, which is the next section.
