---
title: "Administrative distance: which source to believe"
version: 1
---

A router can hear about the same prefix from several places at once: a connected interface, a
static route somebody typed, OSPF, BGP. Their metrics are in different units, so they cannot be
compared. **Administrative distance ranks the sources themselves, and the lower distance wins**,
before any metric is looked at. It is a measure of trust: a route the router can see on its own
cable outranks one somebody typed, and that outranks one a protocol learned from a neighbour.

r1 runs FRR, a routing suite that keeps its own table and hands the winners to the kernel. Its view
of the routes typed so far, with the cable to ra back in:

```
root@r1:~# vtysh -c "show ip route"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

K * 0.0.0.0/0 [0/200] via 10.20.2.2, eth2, 00:00:09
K>* 0.0.0.0/0 [0/100] via 10.20.1.2, eth1, 00:00:10
C>* 10.20.1.0/30 is directly connected, eth1, 00:00:03
C>* 10.20.2.0/30 is directly connected, eth2, 00:00:23
C>* 10.20.10.0/24 is directly connected, eth0, 00:00:23
K>* 10.30.0.0/16 [0/0] via 10.20.1.2, eth1, 00:00:17
K>* 10.30.5.0/24 [0/0] via 10.20.2.2, eth2, 00:00:17
```

Every line is a route, with a letter for where it came from: `K` for a route found in the kernel,
which is everything typed with `ip route`, and `C` for connected. The pair in brackets is
**`[distance/metric]`**. The two defaults are `[0/100]` and `[0/200]`, same distance, so the metric
decides, and `>` marks the one selected, via 10.20.1.2. Both carry `*`, which means both are in the
kernel's forwarding table, as `ip route` showed in the last section. The connected route for
10.20.1.0/30 is 3 seconds old where the other two connected routes are 23: that is the cable to ra
coming back.

Now two routes to the same prefix from the same source, with different distances. Both are typed in
FRR's own configuration language: 10.40.0.0/16 via ra with no distance, which for a static route
means 1, and via rb with distance 200, the number at the end of the line:

```
root@r1:~# vtysh -c "configure terminal" -c "ip route 10.40.0.0/16 10.20.1.2" -c "ip route 10.40.0.0/16 10.20.2.2 200"
root@r1:~# vtysh -c "show ip route 10.40.0.0/16"
Routing entry for 10.40.0.0/16
  Known via "static", distance 200, metric 0
  Last update 00:00:02 ago
    10.20.2.2, via eth2, weight 1

Routing entry for 10.40.0.0/16
  Known via "static", distance 1, metric 0, best
  Last update 00:00:02 ago
  * 10.20.1.2, via eth1, weight 1

root@r1:~# ip route show 10.40.0.0/16
10.40.0.0/16 nhid 26 via 10.20.1.2 dev eth1 proto static metric 20 
```

FRR knows both, `Known via "static"`, and marks the distance 1 route `best`. **The routing suite
keeps every candidate; the kernel gets only the winner**: one line, via 10.20.1.2, `proto static`.
The `metric 20` on it is the number FRR gives the routes it installs in the kernel, and is neither
the distance nor the static route's metric of 0. The route at distance 200 is a **floating static
route**: it floats behind the better one and is installed only if that one goes, for example when
its next hop becomes unreachable. That is the usual way to keep a static backup behind a route a
protocol learned: give the static a distance above the protocol's.

The default distances are a convention, set by Cisco and followed by FRR:

| source | distance |
|---|---|
| connected | 0 |
| static | 1 |
| eBGP (from another autonomous system) | 20 |
| EIGRP, internal (Cisco) | 90 |
| OSPF | 110 |
| RIP | 120 |
| iBGP (from inside the same autonomous system) | 200 |

So when OSPF and RIP both offer a route to the same prefix, OSPF's is used and RIP's waits, whatever
their metrics say. Lessons 16 and 17 meet these protocols; the table is the reason a router running
two of them does not have to compare a hop count with a cost.

Put the three rules in their order, because the order is where mistakes come from. **First the
longest prefix, then the lowest distance, then the lowest metric.** Distance only compares routes to
the same prefix. If RIP offers 10.50.1.0/24 and a static route covers 10.50.0.0/16, a packet for
10.50.1.7 takes RIP's /24, at distance 120, over the static /16 at distance 1, because the longer
prefix was decided before trust was asked about at all.
