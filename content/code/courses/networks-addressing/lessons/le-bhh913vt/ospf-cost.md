---
title: OSPF cost: why four links beat one
version: 1
---

RIP sent pc1's traffic over the direct cable because it was one router away. **OSPF does not count
routers. It adds up a cost on each interface the packet leaves by**, and takes the path with the lowest
total. In this lab the direct cable from r1 to r2 was given a cost of 100, standing for a slow line, and
every other interface kept the cost FRR gave it:

```
root@r1:~# vtysh -c "show ip ospf interface eth4" | grep -E "Cost"
  Router ID 10.20.1.1, Network Type POINTOPOINT, Cost: 10
```

`Cost: 10` on `eth4`, against the `Cost: 100` on `eth1` in the previous section. Normally the cost is
calculated from the interface's speed, a reference bandwidth divided by the link's bandwidth, so a faster
link costs less; typing it by hand, as here, overrides the calculation.

The routes OSPF calculated:

```
root@r1:~# vtysh -c "show ip route ospf"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.20.0.0/30 [110/100] is directly connected, eth1, weight 1, 00:00:27
O>* 10.20.0.4/30 [110/30] via 10.20.0.13, eth4, weight 1, 00:00:06
O>* 10.20.0.8/30 [110/20] via 10.20.0.13, eth4, weight 1, 00:00:14
O   10.20.0.12/30 [110/10] is directly connected, eth4, weight 1, 00:00:27
O   10.20.1.0/24 [110/10] is directly connected, eth0, weight 1, 00:00:27
O>* 10.20.2.0/24 [110/40] via 10.20.0.13, eth4, weight 1, 00:00:06
```

The pair in brackets is **`[distance/cost]`**: 110 is OSPF's administrative distance from lesson 14, the
same on every line, and the second number is the cost of the path. **pc2's network, `10.20.2.0/24`, costs
40, through `10.20.0.13`, which is r4**: the long way round.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"The ring with the OSPF cost of each interface. The cable from r1 to r2 costs 100; every other interface costs 10, including r2&#x27;s interface on pc2&#x27;s network. From r1 to 10.20.2.0/24 the direct path costs 100 plus 10, 110. The path round the ring, through r4, r3 and r2, costs 10 plus 10 plus 10 plus 10, 40, and OSPF chooses it. Router IDs: r1 10.20.1.1, r2 10.20.2.1, r3 10.20.0.9, r4 10.20.0.13.\"><defs><marker id=\"rc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.1.1</text><rect x=\"430\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"440\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.2.1</text><rect x=\"430\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"440\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.0.9</text><rect x=\"190\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.0.13</text><rect x=\"20\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"590\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"600\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.10</text><path d=\"M130 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 95 L590 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 95 L430 95\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M495 130 L495 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M255 130 L255 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"375\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cost 100</text><text x=\"505\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost 10</text><text x=\"375\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost 10</text><text x=\"245\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost 10</text><text x=\"575\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost 10</text><path d=\"M267 133 L267 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><path d=\"M323 260 L427 260\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><path d=\"M483 207 L483 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><rect x=\"20\" y=\"300\" width=\"680\" height=\"66\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">r1 to 10.20.2.0/24, adding the cost of each interface the packet leaves by:</text><text x=\"36\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">direct: 100 + 10 = 110</text><text x=\"300\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">round the ring: 10 + 10 + 10 + 10 = 40, chosen</text><text x=\"36\" y=\"356\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">RIP counted routers instead, and chose the direct cable.</text></svg>", "caption": "Cost is per interface and adds up along the path. Four cheap links beat one expensive one."}
```

Add it up from r1. Leaving by `eth4` towards r4 costs 10, r4 to r3 costs 10, r3 to r2 costs 10, and r2's
interface on pc2's network costs 10: **40**. The direct path costs 100 to reach r2 and 10 more for pc2's
network: **110**. Four cheap links beat one expensive one, and `traceroute` shows the packets going that
way:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  6.554 ms  0.604 ms  0.428 ms
 2  10.20.0.13  0.902 ms  0.219 ms  0.450 ms
 3  10.20.0.9  0.240 ms  0.212 ms  0.093 ms
 4  10.20.0.5  0.252 ms  0.119 ms  0.190 ms
 5  10.20.2.10  1.026 ms  0.274 ms  0.138 ms
```

Five hops where RIP had three: r1, then r4 at `10.20.0.13`, r3 at `10.20.0.9`, r2 at `10.20.0.5`, then pc2.
**The two protocols chose opposite paths on the same cables**, because one counts routers and the other
adds costs.

Two details in the routing table repay a closer look. The lines for r1's own networks, such as
`10.20.0.0/30 [110/100] is directly connected`, have no `>` and no `*`: OSPF knows them, but the connected
route has distance 0 and wins, so OSPF's copy is not used. And `10.20.0.4/30`, the cable between r2 and
r3, costs 30 through r4: 10 to r4, 10 to r3, and 10 for r3's interface on that cable.

OSPF keeps its own view of the same calculation:

```
root@r1:~# vtysh -c "show ip ospf route"
============ OSPF network routing table ============
N    10.20.0.0/30          [100] area: 0.0.0.0
                           directly attached to eth1
N    10.20.0.4/30          [30] area: 0.0.0.0
                           via 10.20.0.13, eth4
N    10.20.0.8/30          [20] area: 0.0.0.0
                           via 10.20.0.13, eth4
N    10.20.0.12/30         [10] area: 0.0.0.0
                           directly attached to eth4
N    10.20.1.0/24          [10] area: 0.0.0.0
                           directly attached to eth0
N    10.20.2.0/24          [40] area: 0.0.0.0
                           via 10.20.0.13, eth4

============ OSPF router routing table =============

============ OSPF external routing table ===========


```

Each network with its total cost in brackets, and the router to hand it to. The **router routing table**
and **external routing table** are empty because nothing in this ring is an area border or brings in
routes from outside OSPF.

## Using cost on purpose

Cost is how you tell OSPF what you prefer. **Make a link more expensive and traffic moves off it**, as long
as another path adds up to less. The arithmetic is the whole tool, and it has one trap: if two paths add up
to the same total, OSPF uses both and splits the traffic between them, which is useful when you meant it
and confusing when you did not.
