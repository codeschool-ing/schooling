---
title: RIP: counting routers
version: 1
---

**RIP** (*Routing Information Protocol*) is the oldest protocol here and the simplest to read. Its
metric is the number of routers between you and a network, and it believes whatever its neighbours say.
Three lines turn it on, typed into FRR's `vtysh` on r1 and the same on the other three:

```
root@r1:~# vtysh -c "configure terminal" -c "router rip" -c "version 2" -c "network 10.20.0.0/16"
```

`version 2` is the version that carries a mask with every route, which is what lesson 12's subnets need;
version 1 assumed the old class boundaries. `network 10.20.0.0/16` says *speak RIP on every interface
with an address inside this range*, which here is all of them.

A few seconds later r1 has heard from both neighbours:

```
root@r1:~# vtysh -c "show ip rip"
Codes: R - RIP, C - connected, S - Static, O - OSPF, B - BGP
Sub-codes:
      (n) - normal, (s) - static, (d) - default, (r) - redistribute,
      (i) - interface

     Network            Next Hop         Metric From            Tag Time
C(i) 10.20.0.0/30       0.0.0.0               1 self              0
R(n) 10.20.0.4/30       10.20.0.2             2 10.20.0.2         0 02:55
R(n) 10.20.0.8/30       10.20.0.13            2 10.20.0.13        0 02:58
C(i) 10.20.0.12/30      0.0.0.0               1 self              0
C(i) 10.20.1.0/24       0.0.0.0               1 self              0
R(n) 10.20.2.0/24       10.20.0.2             2 10.20.0.2         0 02:55
```

Read the `Metric` column. **r1's own networks are at 1, and everything learned from a neighbour is at
2**: the neighbour said 1, and r1 added one for itself. pc2's network, `10.20.2.0/24`, came from
`10.20.0.2`, which is r2 across the direct cable. The `10.20.0.8/30` between r3 and r4 came from r4,
`10.20.0.13`, at the same distance.

The `Time` column is a countdown. Every RIP router sends its whole table to its neighbours every 30
seconds, and **a route that is not refreshed for 180 seconds is declared invalid**; `02:55` is a route
heard five seconds ago. That timer is RIP's only way of noticing a dead neighbour.

The routes are in the kernel now:

```
root@r1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.4/30 nhid 14 via 10.20.0.2 dev eth1 proto rip metric 20 
10.20.0.8/30 nhid 17 via 10.20.0.13 dev eth4 proto rip metric 20 
10.20.0.12/30 dev eth4 proto kernel scope link src 10.20.0.14 
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
10.20.2.0/24 nhid 14 via 10.20.0.2 dev eth1 proto rip metric 20 
```

`proto rip` marks them. The `metric 20` here is not the hop count: it is a number FRR writes on every
route it installs, and lesson 17's BGP routes carry the same 20. pc1 reaches pc2 across the direct cable,
one router between them:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  5.897 ms  0.612 ms  0.503 ms
 2  10.20.0.2  1.022 ms  0.219 ms  0.215 ms
 3  10.20.2.10  1.784 ms  0.669 ms  0.574 ms
```

## What RIP cannot see

**RIP counts routers and nothing else.** A hop over a slow leased line and a hop over a ten-gigabit
fibre both count 1. The OSPF sections of this lesson make the direct cable between r1 and r2 the
expensive one, and RIP has no way to be told.

**Its range is fifteen.** A metric of 16 means unreachable, so a network more than fifteen routers
away cannot be reached with RIP at all. That limit is deliberate, and it exists because of RIP's worst
habit: when a network disappears, neighbours can keep offering each other old versions of the route, each
adding one, **counting to infinity** until the number reaches 16. *Split horizon*, never advertising a
route back out of the interface it was learned on, and *poisoned reverse*, advertising it back as 16,
shorten that, and the 180-second timer still makes RIP slow to forget.

RIP is rarely chosen for a new network. It survives in small equipment, in old installations, and in
exams, because it is the clearest example of distance vector there is. Before OSPF was typed, RIP was
switched off on all four routers:

```
root@r1:~# vtysh -c "configure terminal" -c "no router rip"
```
