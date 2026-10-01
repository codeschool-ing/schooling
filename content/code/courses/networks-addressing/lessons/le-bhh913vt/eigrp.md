---
title: EIGRP: a backup worked out in advance
version: 1
---

**EIGRP** (*Enhanced Interior Gateway Routing Protocol*) was Cisco's own protocol for most of its life.
Cisco published it as an informational RFC, RFC 7868, in 2016, and FRR has an implementation, `eigrpd`,
which this lab used **only to show the tables EIGRP keeps**. Production EIGRP networks are, in practice,
Cisco networks, and the behaviour described here is the protocol's, not a measurement of FRR.

The configuration is two lines, the same on every router:

```
root@r1:~# vtysh -c "configure terminal" -c "router eigrp 64500" -c "network 10.20.0.0/16"
```

The number after `router eigrp` is called an autonomous system number and has to match on every
neighbour. It is EIGRP's own label for the routing domain, unrelated to the BGP numbers of lesson 17,
even though the lab used 64500, a number that reappears there. OSPF was still configured when EIGRP was
added; this section reads EIGRP's own tables and not which protocol's routes the kernel ended up using.

## Neighbours

```
root@r1:~# vtysh -c "show ip eigrp neighbor"

EIGRP neighbors for AS(64500)

H   Address           Interface            Hold   Uptime   SRTT   RTO   Q     Seq  
                                           (sec)           (ms)        Cnt    Num   
0   10.20.0.2         eth1                 14     0        0      2    0      3
0   10.20.0.13        eth4                 12     0        0      2    0      3
```

The two neighbours, r2 and r4. `Hold` is EIGRP's dead timer, counting down from **15 seconds** by default
and reset by a hello every **5 seconds**, which is why it reads 14 and 12 here.

## The topology table

**EIGRP keeps every neighbour's offer, not only the best one.** That is the difference from RIP:

```
root@r1:~# vtysh -c "show ip eigrp topology"

EIGRP Topology Table for AS(64500)/ID(10.20.1.1)

Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply
       r - reply Status, s - sia Status

P  10.20.0.0/30, 1 successors, FD is 28160, serno: 0 
       via Connected, eth1
P  10.20.0.4/30, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.2 (30720/28160), eth1
P  10.20.0.8/30, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.13 (30720/28160), eth4
P  10.20.0.12/30, 1 successors, FD is 28160, serno: 0 
       via Connected, eth4
P  10.20.1.0/24, 1 successors, FD is 28160, serno: 0 
       via Connected, eth0
P  10.20.2.0/24, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.2 (30720/28160), eth1
```

Take pc2's network, `10.20.2.0/24`. `P` means **passive**, the healthy state: EIGRP is not looking for a
route. `1 successors` is the number of best paths, and the **successor** is the neighbour in use, here
`10.20.0.2`, r2, on `eth1`. `FD is 30720` is the **feasible distance**, the metric of the best path from r1.

The pair after the neighbour is **`(30720/28160)`**: r1's distance through that neighbour, and the
**reported distance**, the neighbour's own distance to the network, which r2 told r1. r2 is connected to
pc2's network, so it reports 28160, the same number r1 shows for its own connected networks. The
difference, 2560, is what one more link adds.

With the default settings, the metric is calculated from the slowest bandwidth on the path and the total delay of its interfaces,
not from OSPF's cost, which is why EIGRP chose the direct cable that OSPF avoided: the `cost 100` was an
OSPF setting, and EIGRP sees two equal interfaces.

## Feasible successors, and why there is none here

The reason EIGRP remembers every offer is the **feasible successor**: a second neighbour that can take
over at once, without asking anybody, if the successor fails. Not every neighbour qualifies. **The
feasibility condition is that the neighbour's reported distance is lower than r1's feasible distance**:
a neighbour closer to the network than r1 is cannot be routing through r1, so using it cannot create a
loop.

For `10.20.2.0/24`, the other neighbour is r4, and r4 is further from pc2's network than r1 is. Whatever
it reports is larger than 30720, so it fails the condition, and the table lists one successor and no
backup. If r2 failed, r1 would have to ask its neighbours for a new path, which EIGRP calls going
**active** (`A` in the codes) and its algorithm, **DUAL** (*Diffusing Update Algorithm*), manages.

**A ring gives EIGRP nothing to keep in reserve for the network next door**, because the other way round
is always the longer way. A design where a second neighbour is itself next to the network, such as two
routers both cabled to pc2's LAN, is where feasible successors appear, and failover to one asks nobody.
