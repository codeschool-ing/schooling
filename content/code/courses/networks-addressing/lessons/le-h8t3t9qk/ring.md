---
title: A ring of routers, and one cut
version: 2
---

The ring in this section is not the shared loop of Token Ring. It is four routers, **each cabled to
exactly two neighbours**, every cable a separate link with its own small network, a `/30` (lesson 12
explains the arithmetic of a `/30`: two usable addresses, one for each end). pc1 sits behind r1 and
pc2 behind r2. This is the shape a provider uses round a city, and its whole point is the property a
star lacks: **there are two ways from any router to any other**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The ring scenario of the lab. Four routers in a square: r1 top left, r2 top right, r3 bottom right, r4 bottom left, each cabled to the two beside it, each cable its own /30. pc1 hangs from r1 and pc2 from r2. Before the cut, pc1 reaches pc2 through r1 and r2. The cable r1 to r2 is cut, and the path becomes r1, r4 at 10.20.0.13, r3 at 10.20.0.9, r2 at 10.20.0.5.\"><rect x=\"120\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M155.0 56 L155.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"380\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M415.0 56 L415.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 137.0 L380.0 137.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"206.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"364.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cut</text><path d=\"M279.0 129.0 L291.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M291.0 129.0 L279.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M415.0 154.0 L415.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"401.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"401.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M380.0 267.0 L190.0 267.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"364.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"206.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M155.0 250.0 L155.0 154.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"169.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"169.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><rect x=\"120\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><rect x=\"380\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><rect x=\"380\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><rect x=\"120\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><rect x=\"520\" y=\"110\" width=\"188\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"532\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">before the cut</text><text x=\"532\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r2</text><text x=\"532\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">after the cut</text><text x=\"532\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r4, r3, r2</text></svg>", "caption": "The ring of lesson 3. The numbers beside each cable are the last byte of the address at that end, the ones traceroute prints: 10.20.0.13 is r4, 10.20.0.9 is r3, 10.20.0.5 is r2."}
```

This ring is a network of its own. Save it as `~/netlab/ring.sh`:

```bash
# ~/netlab/ring.sh: four routers in a ring, each cable its own /30, and a PC
# behind r1 and another behind r2. OSPF finds the paths, with a hello every
# second so a broken cable is noticed in four seconds instead of forty.
#
#        pc1    pc2        10.20.0.0/30  r1-r2      10.20.0.8/30   r3-r4
#         |      |         10.20.0.4/30  r2-r3      10.20.0.12/30  r4-r1
#   r4 -- r1 -- r2         10.20.1.0/24  behind r1  10.20.2.0/24   behind r2
#    |           |
#    +--- r3 ----+
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
ospf_p2p r1 10.255.0.1 "eth1 eth4"; ospf_p2p r2 10.255.0.2 "eth1 eth2"
ospf_p2p r3 10.255.0.3 "eth2 eth3"; ospf_p2p r4 10.255.0.4 "eth3 eth4"
wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
```

`ospf_p2p` is the function in `netlab.sh` that writes one router's OSPF configuration, and lesson 16
explains every line of it. The last line waits until pc1 can reach pc2, because OSPF takes a few
seconds to find the paths. Build it with `sudo bash ~/netlab/netlab.sh up ring`.

r1 shows its cables. `eth0` is pc1's network; `eth1` and `eth4` are its two neighbours in the ring:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if171       UP             10.20.0.1/30 fe80::a6:80ff:fe20:1354/64 
eth4@if178       UP             10.20.0.14/30 fe80::76:f0ff:fedf:fe66/64 
eth0@if180       UP             10.20.1.1/24 fe80::1f:23ff:fee7:e9d5/64 
```

`10.20.0.1/30` faces r2 and `10.20.0.14/30` faces r4. (The `@if171`-style suffix is the lab showing
through: it is the number of the interface at the other end of the virtual cable.) With every cable
working, pc1 reaches pc2 the short way, through r1 and r2:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  4.786 ms  0.316 ms  0.270 ms
 2  10.20.0.2  0.260 ms  0.224 ms  0.190 ms
 3  10.20.2.10  0.954 ms  0.251 ms  0.419 ms
```

Two routers, then pc2. Hop 1 is r1's address on pc1's network, and hop 2 is r2's end of the r1–r2
cable.

## The cut

pc1 now starts thirty pings, one every half second, with `-q` so that only the summary prints. While
they run, the cable between r1 and r2 is cut — its end on r1 set down. The ping finished after the
cut, so its summary is printed after the command that cut the cable:

```
root@r1:~# ip link set eth1 down
ana@pc1:~$ ping -c 30 -i 0.5 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
30 packets transmitted, 11 received, +3 errors, 63.3333% packet loss, time 14590ms
rtt min/avg/max/mdev = 0.627/1.016/1.236/0.188 ms
```

**11 of 30 came back**, a loss of 63.3333% over a run of 14590 ms. The 19 that were lost went out
while the network was still deciding where pc2 had gone; at two pings a second, that is about nine
and a half seconds without a path, in this lab. `+3 errors` counts ICMP error messages that came back
in place of an echo: while the routes were changing, a router answered that it had no way to pc2.
Then the ring recovered by itself, and nobody touched pc1, pc2 or a routing table.

Who did? The traceroute after the cut answers part of it:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.832 ms  0.361 ms  0.125 ms
 2  10.20.0.13  0.286 ms  0.235 ms  0.155 ms
 3  10.20.0.9  0.382 ms  0.162 ms  0.175 ms
 4  10.20.0.5  0.263 ms  0.203 ms  0.388 ms
 5  10.20.2.10  0.248 ms  0.414 ms  0.218 ms
root@r1:~# ip route show 10.20.2.0/24
10.20.2.0/24 nhid 22 via 10.20.0.13 dev eth4 proto ospf metric 20 
```

**The packets now go the long way round**: r1, then `10.20.0.13` (r4), `10.20.0.9` (r3) and
`10.20.0.5` (r2) — four routers instead of two. The figure above has those addresses at the end of
each cable. The route on r1 says the rest: `proto ospf` means the routing protocol **OSPF** wrote it,
pointing at r4 through `eth4`. The routers keep telling each other which cables are up, and when one
went down they computed the other way round. Lesson 16 explains how, and why it took the seconds it
did; this lab cuts OSPF's timers to a hello every second so that a break is noticed quickly.

## What a ring buys and what it costs

- **It survives one cut.** Any single cable can fail and every router still reaches every other.
- **It does not survive two.** Cut a second cable anywhere and the ring is two separate chains;
  routers on opposite sides lose each other.
- **The detour can be long.** In a ring of four, a cut can turn one hop into three. In a ring of
  twenty routers, the way round after a cut can cross nineteen cables.
- **It costs one cable per router**, the cheapest arrangement that has a second path at all.

That last point is why providers like rings for metropolitan fibre: one loop of fibre round a city,
and every building on it has two ways out. The next section adds two cables to this same ring and
cuts the same one.
