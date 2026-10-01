---
title: Scalability, growing without starting again
version: 1
---

A design **scales** when it can grow by adding more of the same pieces, without changing the pieces
already there. The test is concrete: when the campus gains a building, what has to change? In a good
design, the new building brings its own distribution pair and access switches, plugs into the core, and
**nothing else is touched**. In a poor one, every router learns a long list of new routes and somebody
edits the firewall rules of every floor.

Two things grow when a network grows: the hardware, and the routing tables. The hierarchy of the first
section takes care of the hardware. The tables are the part people forget, so count them. This is c1's,
the whole of it:

```
root@c1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.4/30 dev eth2 proto kernel scope link src 10.20.0.5 
10.20.0.8/30 dev eth3 proto kernel scope link src 10.20.0.9 
10.20.0.12/30 nhid 24 proto ospf metric 20 
	nexthop via 10.20.0.2 dev eth1 weight 1 
	nexthop via 10.20.0.6 dev eth2 weight 1 
10.20.0.16/30 nhid 33 proto ospf metric 20 
	nexthop via 10.20.0.2 dev eth1 weight 1 
	nexthop via 10.20.0.10 dev eth3 weight 1 
10.20.11.0/24 nhid 25 via 10.20.0.6 dev eth2 proto ospf metric 20 
10.20.12.0/24 nhid 34 via 10.20.0.10 dev eth3 proto ospf metric 20 
root@c1:~# ip route | wc -l
11
```

`wc -l` counts 11 lines, but the table holds **7 routes**: four lines that start with a tab are the
`nexthop` continuations of the two routes above them, which each have two equal paths. The seven are:

- **5 links**, one `/30` per cable: `10.20.0.0/30`, `.4/30` and `.8/30` are c1's own cables (`proto
  kernel`, learnt by having an address on them), and `.12/30` and `.16/30` are cables elsewhere in the
  campus, learnt from OSPF;
- **2 LANs**: `10.20.11.0/24` through d1 and `10.20.12.0/24` through d2.

So every cable adds a route, and every access LAN adds a route, on every router. At this size it does
not matter. With forty buildings, each with a distribution pair and a dozen LANs, it is hundreds of
routes on every core router, every one of them recomputed whenever any cable anywhere goes down.

## Addresses that summarise

The defence is an **address plan that summarises**: addresses handed out in blocks that line up with the
hierarchy, so that one short route can stand for many long ones. The campus already does it in two
places:

- **Every link comes from one /24.** `10.20.0.0/24` cut into `/30`s holds 64 links. Anything outside
  the campus that needs to reach the links needs one route, `10.20.0.0/24`, not one per cable.
- **Every LAN is a /24 inside 10.20.0.0/16.** pc1's `10.20.11.0/24` and pc2's `10.20.12.0/24` sit side
  by side. To the rest of a company's network, the whole campus can be **one route: `10.20.0.0/16`**.

Hand out addresses in the order people ask for them — the accounting LAN here, the next building's
links there — and no route ever summarises, because the blocks do not line up with anything. **An address
plan is cheap on the first day and impossible to change on the thousandth**, since every device, every
firewall rule and every document carries the addresses.

The arithmetic of masks and how many hosts a block holds is lesson 12; cutting one block into
differently sized pieces, as the campus does with its `/30`s and `/24`s, is lesson 13; and making OSPF
announce one summary in place of many routes belongs to lesson 16. This section only asks you to look
at a table and count.

## The other kind of growth

Scalability also means that the people can keep up. A design with one kind of access switch, one kind
of distribution pair and one way of numbering things can be extended by somebody who did not build it.
A design where every building is a special case cannot, however fast its routers are. That is the bridge
to the last section of this lesson: what is not written down does not scale.
