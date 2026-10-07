---
title: "Metrics: two routes to the same place"
version: 2
---

Longest prefix cannot choose between two routes to the same prefix: they are the same length. Then
the **metric** decides, and **the lower metric wins**. It is a cost, and the router takes the
cheaper road. The most common reason to have two such routes is a backup: two ways out, one
preferred, the other waiting.

r1 gets exactly that. The old default goes, and two come in its place, via ra at metric 100 and via
rb at metric 200:

```
root@r1:~# ip route del default via 10.20.1.2
root@r1:~# ip route add default via 10.20.1.2 metric 100
root@r1:~# ip route add default via 10.20.2.2 metric 200
root@r1:~# ip route show default
default via 10.20.1.2 dev eth1 metric 100 
default via 10.20.2.2 dev eth2 metric 200 
root@r1:~# ip route get 198.51.100.7
198.51.100.7 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
```

Both are in the table and only one is used: 198.51.100.7, an address nothing more specific covers,
leaves via ra. The metric 200 route is not wrong and not idle. It is a **backup route**, kept in the
table and ignored for as long as the better one is usable.

Then the cable from r1 to ra is pulled. (In the lab, ra's end of it is switched off, `ip link set eth0 down` at a
root prompt on ra, which r1 sees exactly as a pulled cable: the signal on its port goes.) r1 notices at once:

```
root@r1:~# ip -br link show eth1
eth1@if219       DOWN           02:a6:80:20:13:54 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
root@r1:~# ip route show default
default via 10.20.1.2 dev eth1 metric 100 dead linkdown 
default via 10.20.2.2 dev eth2 metric 200 
root@r1:~# ip route get 198.51.100.7
198.51.100.7 via 10.20.2.2 dev eth2 src 10.20.2.1 uid 0 
    cache 
```

eth1 is `DOWN` with `NO-CARRIER`: the interface is still switched on (`UP` in the flags) and there
is nothing at the other end. The kernel marks the route through it **`dead linkdown`** and stops
choosing it, and the same question now gets the other answer: via rb, eth2. Nobody typed anything,
and no routing protocol was involved. **A route whose interface loses its signal is dropped from the
choice, and the backup behind it takes over.** When the cable came back, the metric 100 route was
chosen again, which the next section's capture, taken afterwards, shows as selected.

That failover has a blind spot, and it is the one that matters in practice. It only fires when r1's
own port loses its signal. Suppose ra crashed but its port stayed lit, or ra and r1 were joined through a switch, or ra lost its
own way out further along. r1's link would stay up, the metric
100 route would stay alive, and r1 would keep sending everything to a router that drops it. **A
static backup protects against a cable, not against a router.** Knowing whether the next router can
still deliver takes something that asks it: the hello messages of a routing protocol, which lesson
16 covers, or a test of the path itself, which some routers can attach to a static route.

Where the metric comes from depends on who made the route. Here it is a number typed by hand, and
Linux treats it as a plain preference. A routing protocol computes it from the network: RIP counts
the routers on the way, OSPF adds up a cost per link derived from its speed, and EIGRP combines
several measurements into one number; lesson 16 takes each apart. **A metric only means something
next to another metric from the same source.** Five hops and a cost of five are not the same five,
and the next section is about what a router does when two sources disagree.
