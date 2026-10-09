---
title: The mesh, and what it costs to count
version: 2
---

A **full mesh** has a cable between every pair of devices. Take the ring of the previous section and
add its two diagonals, r1 to r3 and r2 to r4, and four routers become a full mesh: each one has a
cable to each of the other three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The mesh scenario of the lab: the same four routers in a square, plus the two diagonals, r1 to r3 on 10.20.0.16/30 and r2 to r4 on 10.20.0.20/30. The cable r1 to r2 is cut, and the path becomes r1, r3 at 10.20.0.18, r2 at 10.20.0.5.\"><rect x=\"120\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M155.0 56 L155.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"380\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M415.0 56 L415.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 137.0 L380.0 137.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"206.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"364.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cut</text><path d=\"M279.0 129.0 L291.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M291.0 129.0 L279.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M415.0 154.0 L415.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"401.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"401.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M380.0 267.0 L190.0 267.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"364.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"206.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M155.0 250.0 L155.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"169.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"169.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><path d=\"M189.0 154.0 L381.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"235.1\" y=\"164.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.17</text><text x=\"344.8\" y=\"219.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.18</text><path d=\"M381.0 154.0 L189.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"344.8\" y=\"184.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.21</text><text x=\"235.1\" y=\"239.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.22</text><rect x=\"120\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><rect x=\"380\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><rect x=\"380\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><rect x=\"120\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><rect x=\"520\" y=\"110\" width=\"188\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"532\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">before the cut</text><text x=\"532\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r2</text><text x=\"532\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">after the cut</text><text x=\"532\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r3, r2</text></svg>", "caption": "The same ring with its two diagonals: six cables, one between every pair of four routers. After the same cut the detour takes the diagonal to r3, one router fewer than the ring needed."}
```

The mesh is the ring's file with the two diagonals added, and OSPF on them too. Save it as
`~/netlab/mesh.sh` and build it with `sudo bash ~/netlab/netlab.sh up mesh`:

```bash
# ~/netlab/mesh.sh: the ring of ring.sh with its two diagonals added, so every
# router has a cable to every other one: 10.20.0.16/30 joins r1 and r3, and
# 10.20.0.20/30 joins r2 and r4.
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
link r1 eth5 r3 eth5; addr r1 eth5 10.20.0.17/30; addr r3 eth5 10.20.0.18/30
link r2 eth6 r4 eth6; addr r2 eth6 10.20.0.21/30; addr r4 eth6 10.20.0.22/30
ospf_p2p r1 10.255.0.1 "eth1 eth4 eth5"; ospf_p2p r2 10.255.0.2 "eth1 eth2 eth6"
ospf_p2p r3 10.255.0.3 "eth2 eth3 eth5"; ospf_p2p r4 10.255.0.4 "eth3 eth4 eth6"
wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
```

r1 now has three cables into the network instead of two. The new one is `eth5`, on the diagonal to r3:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if183       UP             10.20.0.1/30 fe80::a6:80ff:fe20:1354/64 
eth4@if190       UP             10.20.0.14/30 fe80::76:f0ff:fedf:fe66/64 
eth0@if192       UP             10.20.1.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth5@if195       UP             10.20.0.17/30 fe80::7:c2ff:fe64:4ef/64 
```

With everything working, nothing changes for pc1. The direct cable to r2 is still the shortest way:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  4.085 ms  0.335 ms  0.432 ms
 2  10.20.0.2  0.297 ms  0.538 ms  0.280 ms
 3  10.20.2.10  1.310 ms  0.324 ms  0.398 ms
```

Then the same experiment as on the ring: thirty pings, one every half second, and the same cable
cut, r1 to r2, while they run.

```
root@r1:~# ip link set eth1 down
ana@pc1:~$ ping -c 30 -i 0.5 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
30 packets transmitted, 27 received, 10% packet loss, time 14574ms
rtt min/avg/max/mdev = 0.555/1.138/2.445/0.382 ms
```

**27 of 30 came back: 10% loss, three pings.** The ring lost 19 to the same cut. And the new path is
shorter than the ring's detour:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.952 ms  0.202 ms  0.171 ms
 2  10.20.0.18  0.321 ms  0.218 ms  0.145 ms
 3  10.20.0.5  0.365 ms  0.284 ms  0.211 ms
 4  10.20.2.10  0.338 ms  0.442 ms  0.232 ms
```

r1, then `10.20.0.18` — r3, reached across the diagonal — then r2 at `10.20.0.5`. **Three routers
instead of the ring's four**, because the mesh had a cable that went most of the way already.

Be careful with the comparison. Each scenario ran once, and how many pings a cut costs depends on
how quickly the routers notice and recompute, which is lesson 16's subject and which this lab
speeds up on purpose. What the two runs show reliably is the shape: **a mesh has more ways round,
and the way round is shorter**. In this four-router mesh, any two cables can fail and every router
still reaches every other, where the ring was split by two cuts.

## Counting cables

The mesh's price is cables, and it grows faster than people expect. Each of *n* devices needs a
cable to each of the other *n − 1*, and each cable joins two devices, so a full mesh needs

**n × (n − 1) / 2 cables.**

| devices | cables in a full mesh | cables in a ring |
|---|---|---|
| 4 | 6 | 4 |
| 10 | 45 | 10 |
| 50 | 1225 | 50 |

Four routers is the lab's six. Ten is 45, which is already a cupboard nobody wants to label. Fifty
is 1,225 cables, and every router would need 49 ports for them. Adding the fifty-first device means
fifty new cables, one to every device already there.

So nobody builds a full mesh of an office. **A partial mesh** is what real networks use: a mesh
among the few devices whose failure would hurt everybody — the core routers, the links between data
centres — and something cheaper everywhere else. A full mesh appears where the count is small and
the stakes are high: two or three core routers, or a handful of sites joined by tunnels, the kind of
link lesson 4 builds.

There is a second, quieter cost. With more ways round, the routers have more to work out and you
have more to read: a mesh's routing table is harder to predict by eye, and a fault on a backup path
can stay hidden until the day it is needed. Lesson 6 calls that by its name — redundancy that has
never been tested.
