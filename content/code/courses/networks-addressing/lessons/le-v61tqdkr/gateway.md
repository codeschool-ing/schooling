---
title: "The default gateway: one router's address"
version: 1
---

"Gateway" sounds like a device. In a host's configuration it is an **address**: **the default
gateway is the address of the router a host sends every packet to when the destination is not on
its own network.** pc1's routing table says so in two lines:

```
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.21 
ana@pc1:~$ ip neigh
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

`10.20.10.0/24 dev eth0` says that the office network is directly on `eth0`; a packet for any
address in it goes straight to its owner. `default via 10.20.10.1` says that everything else goes
to 10.20.10.1, r1's office address. The neighbour table holds one entry, the server's, left over
from the network card section.

Now pc1 pings a machine beyond the router, while tcpdump on pc1 itself watches its card. tcpdump was
started first and printed when it had its two packets, so its output comes after the ping:

```
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=13.8 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 13.754/13.754/13.754/0.000 ms
root@pc1:~# timeout 5 tcpdump -n -e -c 2 -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:13:11.759016 02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 192.0.2.80: ICMP echo request, id 23, seq 1, length 64
15:13:11.770325 02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 192.0.2.80 > 10.20.10.21: ICMP echo reply, id 23, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@pc1:~$ ip neigh
10.20.10.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 REACHABLE 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
root@r1:~# ip -br link show eth0
eth0@if85        UP             02:1f:23:e7:e9:d5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

Read the first captured frame from left to right. **The frame is addressed to `02:1f:23:e7:e9:d5`,
while the packet inside it is addressed to `192.0.2.80`.** The last command shows whose MAC that is:
r1's `eth0`. pc1 never asked for the MAC of 192.0.2.80, and it could not have: ARP only reaches
machines on the same link, and 192.0.2.80 is two networks away. It asked for the gateway's MAC
instead, which is why the neighbour table now has a second line, `10.20.10.1 ... 02:1f:23:e7:e9:d5`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The frame pc1 sent when it pinged 192.0.2.80, as tcpdump captured it, drawn as two nested boxes. The outer box is the Ethernet frame: destination MAC 02:1f:23:e7:e9:d5, which is r1, the gateway, and source MAC 02:25:70:bc:29:c6, pc1. Inside it is the IP packet: source 10.20.10.21 and destination 192.0.2.80, the far server. The frame only crosses the office link and is replaced at r1; the packet's addresses travel the whole way.\"><defs><marker id=\"l2-frame-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"692\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Ethernet frame: valid on the office link only</text><rect x=\"26\" y=\"62\" width=\"190\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">destination MAC</text><text x=\"36\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">02:1f:23:e7:e9:d5</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">r1, the gateway</text><rect x=\"226\" y=\"62\" width=\"190\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"236\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">source MAC</text><text x=\"236\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">02:25:70:bc:29:c6</text><text x=\"236\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pc1</text><rect x=\"426\" y=\"62\" width=\"268\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IP packet: kept to the end</text><text x=\"436\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21 &gt; 192.0.2.80</text><text x=\"436\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pc1 to the far server</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">at r1 the frame is replaced; the packet goes on inside a new one</text></svg>", "caption": "One frame from pc1's capture: two addresses for the next device, two for the ends of the journey."}
```

**Two pairs of addresses, with two different reaches.** The IP addresses name the two ends of the
journey and stay in the packet all the way; the MAC addresses name this link's sender and receiver
and are thrown away at r1, which wraps the same packet in a new frame for the provider's link. The
reply came back with `ttl=62`, the two routers of lesson 1, and through the same gateway: its frame
is from `02:1f:23:e7:e9:d5` to pc1.

The round trip, 13.8 ms, is this lab's virtual computer at work and not a measurement of any
network.

## Why "default"

A host can have more routes than one, and lesson 14 reads tables with many. The default route is
the one used when no other line matches, which on an ordinary office PC is every address outside
its own network. One host, one network, one way out: that is what makes a single gateway address
enough for most machines.

**The gateway has to be in the host's own network**, because the host reaches it by ARP and a frame,
not by routing. pc1's gateway, 10.20.10.1, is inside 10.20.10.0/24, the network on `eth0`. A
gateway outside that range would be a route that needs a route to reach it.

## The other meaning of the word

Outside a routing table, "gateway" still names a device: **one that translates between two
different systems**, not merely forwarding the same protocol from one network to another. A VoIP
gateway turns a telephone line into calls over IP; an e-mail gateway passes messages between two
mail systems; a gateway in a factory or a smart home turns a sensor network that does not speak IP
into one that does. Older texts and some operating systems call any router a gateway, because the
first routers were exactly that, the way into another network. When you read the word, ask whether
it is an address in a configuration or a box that changes the language of the traffic.
