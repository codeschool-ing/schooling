---
title: Router on a stick
version: 1
---

**A router on a stick is a router with one physical port, plugged into a trunk, holding one address
in every VLAN the trunk carries.** The name is the drawing: one cable, the stick, between the switch
and the router. The router does not need a port per VLAN because the trunk already tells it, on
every frame, which VLAN the frame came from.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Router on a stick, the lab for lesson 22. On the left, three machines plugged into switch sw1: pc1, 10.20.10.21, in VLAN 10 on port p1, gateway 10.20.10.1; srv, 10.20.10.10, in VLAN 10 on port p3, gateway 10.20.10.1; pc2, 10.20.20.22, in VLAN 20 on port p2, gateway 10.20.20.1. On the right, router r1, joined to sw1 by one cable from port p8, a trunk carrying VLANs 10 and 20 tagged. r1 has one port, eth0, and two VLAN interfaces on it: eth0.10 with 10.20.10.1/24 and eth0.20 with 10.20.20.1/24.\"><defs><marker id=\"v22s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"190\" y1=\"51\" x2=\"300\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"20\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"178\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21</text><text x=\"32\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.10.1</text><text x=\"292\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"190\" y1=\"125\" x2=\"300\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"94\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"178\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"32\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.10</text><text x=\"32\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.10.1</text><text x=\"292\" y=\"107\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><line x1=\"190\" y1=\"199\" x2=\"300\" y2=\"138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"168\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"178\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"32\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.22</text><text x=\"32\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.20.1</text><text x=\"292\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><rect x=\"300\" y=\"80\" width=\"100\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><line x1=\"400\" y1=\"115\" x2=\"520\" y2=\"115\" stroke=\"var(--paper)\" stroke-width=\"3\"></line><text x=\"408\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p8</text><text x=\"460\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the trunk: VLANs 10 and 20, tagged</text><rect x=\"520\" y=\"60\" width=\"190\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"534\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"534\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">eth0.10  10.20.10.1/24</text><text x=\"534\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">eth0.20  10.20.20.1/24</text><text x=\"534\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one port: eth0</text></svg>", "caption": "One cable between the switch and the router, and on it every VLAN the router serves. The router answers each VLAN from its own interface, at the address that VLAN's machines use as their gateway."}
```

On r1 the trunk arrives on eth0. Linux gives each VLAN its own interface on top of it, and the first
two commands create them:

```
root@r1:~# ip link add link eth0 name eth0.10 type vlan id 10
root@r1:~# ip link add link eth0 name eth0.20 type vlan id 20
root@r1:~# ip addr add 10.20.10.1/24 dev eth0.10 && ip addr add 10.20.20.1/24 dev eth0.20
root@r1:~# ip link set eth0.10 up && ip link set eth0.20 up
```

`eth0.10` is a **VLAN interface**: a frame that arrives on eth0 tagged with VLAN 10 is delivered to
`eth0.10` with the tag removed, and a packet sent out of `eth0.10` leaves eth0 tagged with VLAN 10.
Each one then gets the address the PCs of its VLAN already name as their gateway. Cisco calls these
**subinterfaces** and writes them `interface GigabitEthernet0/0.10` with an `encapsulation dot1Q
10` line inside; the idea is the same, and so is the number, which has to match the VLAN on the
switch. What r1 now holds:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0.10@eth0     UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth0.20@eth0     UP             10.20.20.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth0@if519       UP             fe80::1f:23ff:fee7:e9d5/64 
root@r1:~# ip route
10.20.10.0/24 dev eth0.10 proto kernel scope link src 10.20.10.1 
10.20.20.0/24 dev eth0.20 proto kernel scope link src 10.20.20.1 
```

Two interfaces, `eth0.10@eth0` and `eth0.20@eth0`, each with its own subnet, both riding on eth0.
The link-local IPv6 address is the same on all three, `fe80::1f:23ff:fee7:e9d5`, because it is built
from the MAC address (lesson 9) and the three interfaces share one MAC. The routing table needed no
route typed by hand: **r1 is directly connected to both subnets**, so the two `proto kernel` lines
that appeared with the addresses are the whole of it. The lab built r1 as a router, which means
forwarding between interfaces was already switched on.

```
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.161/2.241/3.321/1.080 ms
ana@pc1:~$ traceroute -n 10.20.20.22
traceroute to 10.20.20.22 (10.20.20.22), 30 hops max, 60 byte packets
 1  10.20.10.1  2.189 ms  0.456 ms  0.441 ms
 2  10.20.20.22  0.450 ms  0.247 ms  0.325 ms
ana@pc2:~$ curl -s http://10.20.10.10/
served by srv
```

pc1 reaches pc2: two transmitted, two received. The traceroute shows the shape, with **one hop
through 10.20.10.1, r1's address in VLAN 10, and pc2 at the second**. And pc2, in VLAN 20, fetches
the web page from srv in VLAN 10, which is the reason the router was put there.

Nothing on the PCs changed. They were already sending to 10.20.10.1 and 10.20.20.1; the difference
is that somebody now answers to those addresses. A gateway configured before the router exists is a
normal state of affairs in a network being built, and the `INCOMPLETE` entry of the last section is
what it looks like.

Router on a stick is common where the traffic between VLANs is light: a small office, a branch with
a router that came with one or two ports, a lab. It costs one router port and one switch port for
any number of VLANs, up to the 4094 the tag can name. What it costs in capacity is the subject of
the next section, which watches a single ping cross the stick.
