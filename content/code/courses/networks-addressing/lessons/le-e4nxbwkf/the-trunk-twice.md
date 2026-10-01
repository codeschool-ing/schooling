---
title: One ping, four crossings
version: 1
---

It is easy to picture the router as sitting between the two VLANs, with traffic flowing through it
from one side to the other. With a router on a stick there is no other side. **Every packet routed
from one VLAN to another goes up the trunk to the router and comes back down the same cable**, once
in each VLAN.

sw1 listened on p8, the trunk to r1, while pc1 sent one ping to pc2. The capture ended after the
ping, so its output comes second:

```
ana@pc1:~$ ping -c 1 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 2.163/2.163/2.163/0.000 ms
root@sw1:~# timeout 6 tcpdump -n -e -i p8 -c 4 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on p8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:21:22.386201 02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.20.22: ICMP echo request, id 139, seq 1, length 64
09:21:22.387313 02:1f:23:e7:e9:d5 > 02:fd:f2:d2:63:ba, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.20.22: ICMP echo request, id 139, seq 1, length 64
09:21:22.387713 02:fd:f2:d2:63:ba > 02:1f:23:e7:e9:d5, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.10.21: ICMP echo reply, id 139, seq 1, length 64
09:21:22.387765 02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.10.21: ICMP echo reply, id 139, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four frames for one ping, the first stamped `.386201` and the last `.387765` within the same
second. Read the MAC addresses and the VLAN of each:

1. `02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5`, `vlan 10`: pc1's echo request, going up the stick to
   r1's MAC, in VLAN 10.
2. `02:1f:23:e7:e9:d5 > 02:fd:f2:d2:63:ba`, `vlan 20`: the same request, routed, coming back down
   from r1 to pc2, now in VLAN 20.
3. `02:fd:f2:d2:63:ba > 02:1f:23:e7:e9:d5`, `vlan 20`: pc2's echo reply, going up to r1.
4. `02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6`, `vlan 10`: the reply, routed, coming back down to pc1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"One ping from pc1 to pc2 through a router on a stick, as a sequence from top to bottom. Four lifelines: pc1, pc2, sw1 and r1. pc1 sends the echo request untagged to sw1. Crossing 1: sw1 sends it up the trunk to r1 in VLAN 10, captured at .386201. Crossing 2: r1 sends it back down to sw1 in VLAN 20, at .387313. sw1 delivers it untagged to pc2. pc2 sends the echo reply untagged to sw1. Crossing 3: sw1 sends the reply up to r1 in VLAN 20, at .387713. Crossing 4: r1 sends it back down in VLAN 10, at .387765. sw1 delivers it untagged to pc1. The four crossings are on the trunk p8 between sw1 and r1, where tcpdump listened.\"><defs><marker id=\"v22t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"400\" y=\"58\" width=\"240\" height=\"244\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></rect><line x1=\"70\" y1=\"50\" x2=\"70\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"30\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><line x1=\"190\" y1=\"50\" x2=\"190\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><line x1=\"400\" y1=\"50\" x2=\"400\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"360\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><line x1=\"640\" y1=\"50\" x2=\"640\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"600\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><line x1=\"70\" y1=\"84\" x2=\"394\" y2=\"84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"235.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">request, untagged</text><line x1=\"400\" y1=\"112\" x2=\"634\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · request, VLAN 10</text><text x=\"392\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.386201</text><line x1=\"640\" y1=\"140\" x2=\"406\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 · request, VLAN 20</text><text x=\"392\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387313</text><line x1=\"400\" y1=\"168\" x2=\"196\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"295.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">request, untagged</text><line x1=\"190\" y1=\"196\" x2=\"394\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"295.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reply, untagged</text><line x1=\"400\" y1=\"224\" x2=\"634\" y2=\"224\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · reply, VLAN 20</text><text x=\"392\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387713</text><line x1=\"640\" y1=\"252\" x2=\"406\" y2=\"252\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · reply, VLAN 10</text><text x=\"392\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387765</text><line x1=\"400\" y1=\"280\" x2=\"76\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"235.0\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reply, untagged</text><text x=\"520\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the trunk p8, where tcpdump listened</text></svg>", "caption": "One ping, read from the top. The request and the reply each cross the trunk twice, once in each VLAN; the times are the ones tcpdump stamped on p8, within the same second."}
```

The IP addresses do not change at any point, `10.20.10.21 > 10.20.20.22` going and the reverse
coming back. What changes is the frame around the packet: **at each hop through the router, the MAC
addresses and the VLAN tag are rewritten, and the IP addresses inside stay as they were** (the
router also lowers the TTL by one, which this capture does not print). That is what routing does
to every packet, seen here on one cable. Every frame is 102 bytes, the tagged size
lesson 19 measured.

The cost follows from the count. **A trunk to a router on a stick carries every routed packet twice**,
once up and once down. The cable is full duplex, so the trip up and the trip down use the two
directions of it and do not compete with each other; but every conversation between every pair of
VLANs shares those two directions, along with anything addressed to the router itself. If the stick
is a 1 Gb/s link, then 1 Gb/s each way is the most that can cross between all the VLANs together,
however fast the switch is inside. Traffic that stays within one VLAN never touches the stick: pc1
and srv talk through sw1 alone.

That is why the design is common in small places and rare in large ones. When the traffic between
VLANs grows, the options are a faster or aggregated link to the router (lesson 21 bundles two cables
into one), or moving the routing to where the traffic already is, inside the switch, which is the
next section.
