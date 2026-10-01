---
title: "A relay: DHCP across a router"
version: 1
---

DHCP starts with a broadcast, and **a router does not forward broadcasts**: that is what makes it
the edge of a broadcast domain, which lesson 18 measures. pc4 is on the second floor, 10.20.20.0/24,
on the far side of r1 from the server. Here it asks for an address, and `timeout 12` stops the
client after twelve seconds:

```
ana@pc4:~$ sudo timeout 12 dhclient -v -1 eth0 2>&1 | grep -E "DHCP|bound|No"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0x3731d01b)
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 5 (xid=0x3731d01b)
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 14 (xid=0x3731d01b)
```

Three DISCOVERs, the client waiting 3, then 5, then 14 seconds between them as it backs off, and
not one OFFER. srv never heard them. Its file already holds a scope for 10.20.20.0, so the address
is there to lend; what is missing is a way for the question to reach it.

One answer is a DHCP server on every subnet, which is many servers to keep in step. The usual
answer is a **relay agent** on the router. It listens for DHCP broadcasts on the client's side and
forwards each one, as an ordinary unicast packet, to a server it was told about. On Linux that is
ISC's `dhcrelay`; on a Cisco router it is one line on the interface, `ip helper-address`, which this
lab does not run. Here, `-id eth2` names the downstream side, pc4's, `-iu eth0` the upstream side
towards srv, and 10.20.10.10 is the server:

```
root@r1:~# dhcrelay -4 -iu eth0 -id eth2 10.20.10.10
Requesting: eth0 as upstream: Y downstream: N
Requesting: eth2 as upstream: N downstream: Y
Internet Systems Consortium DHCP Relay Agent 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Listening on LPF/eth2/02:26:62:13:4f:3c
Sending on   LPF/eth2/02:26:62:13:4f:3c
Listening on LPF/eth0/02:1f:23:e7:e9:d5
Sending on   LPF/eth0/02:1f:23:e7:e9:d5
Sending on   Socket/fallback
```

pc4 asks again, and this time it is answered. On srv, a `tcpdump` had been started in a second
terminal; it prints after pc4's command because it printed when it ended:

```
ana@pc4:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xf0af884c)
DHCPOFFER of 10.20.20.100 from 10.20.20.1
DHCPREQUEST for 10.20.20.100 on eth0 to 255.255.255.255 port 67 (xid=0x4c88aff0)
DHCPACK of 10.20.20.100 from 10.20.20.1 (xid=0xf0af884c)
bound to 10.20.20.100 -- renewal in 250 seconds.
root@srv:~# timeout 15 tcpdump -n -i eth0 -c 4 port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:13.056946 IP 10.20.10.1.67 > 10.20.10.10.67: BOOTP/DHCP, Request from 02:25:46:c1:26:7d, length 300
08:21:14.085697 IP 10.20.10.10.67 > 10.20.20.1.67: BOOTP/DHCP, Reply, length 300
08:21:14.099165 IP 10.20.10.1.67 > 10.20.10.10.67: BOOTP/DHCP, Request from 02:25:46:c1:26:7d, length 300
08:21:14.107376 IP 10.20.10.10.67 > 10.20.20.1.67: BOOTP/DHCP, Reply, length 300
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

From pc4 the exchange looks like any other DORA, with one difference: the offer comes `from
10.20.20.1`, r1's address on pc4's floor, because the relay is the one talking to it. The capture on
srv shows the other half. The requests arrive as `10.20.10.1.67 > 10.20.10.10.67`, from r1, port 67
to port 67, with pc4's MAC address still inside: `Request from 02:25:46:c1:26:7d`.

**The replies go to 10.20.20.1, not to the address the requests came from.** Before forwarding, the
relay wrote its own address on the client's subnet into a field of the request called **giaddr**
(*gateway IP address*), and the server used that field twice: to know where to send the reply, and
to choose the scope. 10.20.20.1 falls inside `subnet 10.20.20.0`, so pc4 was offered 10.20.20.100,
from that scope's pool. This `tcpdump` does not decode the field, which takes `-v`, but the
destination of the replies is the field, read back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The DHCP relay on r1. On the left, pc4's floor, 10.20.20.0/24; on the right, the office, 10.20.10.0/24; r1 sits on both. pc4 broadcasts from 0.0.0.0 to 255.255.255.255. r1 forwards it as a unicast from 10.20.10.1 to srv at 10.20.10.10, with the giaddr field set to 10.20.20.1. srv replies to 10.20.10.10 &gt; 10.20.20.1, the giaddr, and r1 passes pc4 an offer of 10.20.20.100, from 10.20.20.1.\"><defs><marker id=\"dr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"12\" width=\"348\" height=\"228\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"362\" y=\"12\" width=\"348\" height=\"228\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"20\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"80\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">client</text><rect x=\"300\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"360\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relay</text><rect x=\"580\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"640\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">DHCP server</text><line x1=\"142\" y1=\"120\" x2=\"298\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"220\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.0.0.0 &gt; 255.255.255.255</text><text x=\"220\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">broadcast</text><line x1=\"422\" y1=\"120\" x2=\"578\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"500\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.10.1 &gt; 10.20.10.10</text><text x=\"500\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">unicast, giaddr 10.20.20.1</text><line x1=\"578\" y1=\"182\" x2=\"422\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"500\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.10.10 &gt; 10.20.20.1</text><text x=\"500\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reply to the giaddr</text><line x1=\"298\" y1=\"182\" x2=\"142\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"220\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">offer of 10.20.20.100</text><text x=\"220\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">from 10.20.20.1</text><text x=\"20\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pc4's floor, 10.20.20.0/24</text><text x=\"700\" y=\"226\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the office, 10.20.10.0/24</text></svg>", "caption": "The relay turns pc4's broadcast into a unicast to srv, and the giaddr it adds is both where the reply goes and which scope is used."}
```

And with the address came that scope's options:

```
ana@pc4:~$ ip route
default via 10.20.20.1 dev eth0 
10.20.20.0/24 dev eth0 proto kernel scope link src 10.20.20.100 
```

The default route is 10.20.20.1, its own floor's gateway. srv's own gateway, 10.20.10.1, would
have been useless to pc4, which has no way to reach the office subnet directly. **The scope is
chosen by where the client is, and the relay is what tells the server where that is.**

A relay goes on every router interface that faces clients, and one server, or a pair of them for
redundancy, then serves a whole building. The cost is a dependency on the routers between. If r1's
relay stops, a new client on the second floor gets no address at all. A client that already has one
can still renew it, because a renewal is sent by unicast to the server, and r1 routes it like any
other packet.
