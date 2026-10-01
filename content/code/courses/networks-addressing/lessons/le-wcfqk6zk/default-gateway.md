---
title: "The default route: where everything else goes"
version: 1
---

The simplest route to add is the one that covers everything. **The default route is the prefix
0.0.0.0/0: zero bits to compare, so every address matches it.** It is where a packet goes when
nothing more specific claims it, and on a host it has a more familiar name, the default gateway.
r1 gets one towards ra:

```
root@r1:~# ip route add default via 10.20.1.2
root@r1:~# ip route
default via 10.20.1.2 dev eth1 
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
```

`default via 10.20.1.2 dev eth1`. Only the next hop was typed; r1 worked out `dev eth1` itself,
because 10.20.1.2 is inside 10.20.1.0/30, the connected route on eth1. That is a rule rather than a
convenience. **A next hop must be on a network the router is directly connected to**, because the
router delivers the packet to it by its hardware address, across one cable. Linux refuses a `via`
it cannot reach that way.

pc1 tries again, with traceroute this time:

```
ana@pc1:~$ traceroute -n 10.30.5.10
traceroute to 10.30.5.10 (10.30.5.10), 30 hops max, 60 byte packets
 1  10.20.10.1  2.829 ms  0.366 ms  0.189 ms
 2  10.20.1.2  1.062 ms  0.243 ms  0.201 ms
 3  10.30.5.10  2.240 ms  0.356 ms  0.229 ms
```

Three hops: r1 at 10.20.10.1, ra at 10.20.1.2, and far1. r1 still has no route that mentions
10.30.0.0/16; the default carried the packet to ra, and ra, which is on that network, delivered it.
(The times are this lab's one computer talking to itself.)

**A route works in one direction.** The traceroute's replies came back because ra and rb already
had a route for 10.20.0.0/16 pointing at r1, set up with the lab and not typed in this lesson, and
far1's own default points at ra. Remove ra's route and r1's default would still deliver every
packet, and none of the answers would find their way home. When a ping fails, the route that is
missing is as likely to be on the way back as on the way out.

A host is the same machine with a shorter table. pc1's is its own subnet and `default via
10.20.10.1`, the two lines that lesson 10 saw DHCP deliver: an address with its mask, and the
gateway from `option routers`. The gateway must be inside the host's own subnet, for the same reason
a router's next hop must be.

Most routers have a default too, pointing towards the rest of the world: an office router at its
provider, a branch at head office. It makes the table short, and it has a price. **A router with a
default never says `Destination Net Unreachable`**; it sends whatever it does not know up the
default, and a mistake travels in that direction. Lesson 13 showed the worst case: two routers
whose routes pointed at each other passed a packet for an empty address back and forth until its
TTL ran out.
