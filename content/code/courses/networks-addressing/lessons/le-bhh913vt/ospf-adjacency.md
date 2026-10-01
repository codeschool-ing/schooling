---
title: OSPF: neighbours and one shared map
version: 1
---

**OSPF** (*Open Shortest Path First*) is the link-state protocol, and the one you are most likely to meet
inside a company network. Its configuration names the interfaces and the area, and sets two things per
interface that the next section explains:

```
root@r1:~# vtysh -c "configure terminal" -c "interface eth1" -c "ip ospf network point-to-point" -c "ip ospf cost 100" -c "interface eth2" -c "ip ospf network point-to-point" -c "interface eth3" -c "ip ospf network point-to-point" -c "interface eth4" -c "ip ospf network point-to-point" -c "router ospf" -c "network 10.20.0.0/16 area 0"
```

`network 10.20.0.0/16 area 0` runs OSPF on every interface inside that range and puts them in **area 0**,
the backbone. A large OSPF network is split into areas joined to area 0, so that not every router has to
hold every detail; this ring is small enough for one. `ip ospf network point-to-point` tells OSPF that
each cable has exactly two routers on it. On an Ethernet segment OSPF otherwise expects many routers and
elects a **designated router** to speak for the segment, which a cable between two routers does not need.
`ip ospf cost 100` on `eth1` is for the next section.

## Neighbours

OSPF finds its neighbours with hello packets, and lists them:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          13.122s           38.490s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.20.0.13        1 Full/-          13.129s           31.744s 10.20.0.13      eth4:10.20.0.14                      0     0     0

```

Two neighbours, both **`Full`**, which is the state OSPF reaches when two routers have finished
exchanging their databases and hold identical copies. Before that a neighbour passes through `Init`,
`2-Way`, `ExStart`, `Exchange` and `Loading`; a neighbour stuck in one of those is the first thing to look
for when OSPF misbehaves. The `-` after the slash is the designated-router role, empty because the links
are point-to-point.

The `Dead Time` column counts down. Each hello from a neighbour resets it, and if it reaches zero the
neighbour is declared dead. The interface shows the two timers behind it:

```
root@r1:~# vtysh -c "show ip ospf interface eth1" | grep -E "Cost|Timer|Network Type"
  Router ID 10.20.1.1, Network Type POINTOPOINT, Cost: 100
  Timer intervals configured, Hello 10s, Dead 40s, Wait 40s, Retransmit 5
```

**A hello every 10 seconds, and a neighbour declared dead after 40 seconds of silence**: the defaults.
Two routers only become neighbours if those timers match, along with the area and the network type, so a
mismatch shows up as a neighbour that never appears rather than as an error.

## Router IDs

Every OSPF router has a **router ID**, a 32-bit number written like an address. r1's is `10.20.1.1`; its
neighbours are `10.20.2.1` (r2) and `10.20.0.13` (r4). None was typed, so each router picked one of its
own addresses, in all four cases the highest. Lesson 3's ring set them by hand with `ospf router-id`, which
is the better habit: **an ID picked from whichever addresses exist is an ID that changes when the
addresses do**.

## One map on every router

Each router describes its own links in a **router LSA** (*link-state advertisement*) and floods it to
every router in the area. The collection is the **link-state database**:

```
root@r1:~# vtysh -c "show ip ospf database"

       OSPF Router with ID (10.20.1.1)

                Router Link States (Area 0.0.0.0)

Link ID         ADV Router      Age  Seq#       CkSum  Link count
10.20.0.9      10.20.0.9         18 0x80000004 0xc70c 4
10.20.0.13     10.20.0.13        17 0x80000004 0x2f91 4
10.20.1.1      10.20.1.1         20 0x80000005 0xde14 5
10.20.2.1      10.20.2.1         19 0x80000005 0x8c78 5


```

Four routers, four router LSAs, and **every router in the area holds this same list**. That is the point
of link state: nobody passes on a summary of somebody else's opinion, so every router computes its paths
from the same facts with Dijkstra's shortest-path-first algorithm, which is the *SPF* in the name.

The `Link count` column checks out against the drawing. On a point-to-point cable OSPF describes two
things, the neighbour and the `/30` itself, so r1's two cables give four links and its LAN a fifth: **5**.
r2 has the same shape. r3 and r4 have two cables and no LAN: **4**. `Seq#` goes up each time a router
re-describes its links, which is how the others tell a newer LSA from an older copy.
