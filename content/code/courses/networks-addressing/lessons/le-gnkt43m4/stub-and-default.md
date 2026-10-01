---
title: A stub network needs only a default
version: 1
---

A **stub network** has one way in and one way out, and no traffic crosses it on the way to somewhere
else. pc3's side of the lab can be made into one: if r3 sends everything that is not local to r1, over
the spare cable, it needs exactly one route, whatever is added to the rest of the network later.

The route that matches everything is the **default route**, `0.0.0.0/0`, which lesson 14 showed losing
to any longer prefix and winning when nothing else matches. r3 deletes its two specific routes for
pc1's network, the primary and the floating one, and adds a default instead:

```
root@r3:~# ip route del 10.20.1.0/24 via 10.20.23.1
root@r3:~# ip route del 10.20.1.0/24 via 10.20.13.1 metric 200
root@r3:~# ip route add default via 10.20.13.1
root@r3:~# ip route
default via 10.20.13.1 dev eth3 
10.20.3.0/24 dev eth0 proto kernel scope link src 10.20.3.1 
10.20.13.0/30 dev eth3 proto kernel scope link src 10.20.13.2 
10.20.23.0/30 dev eth2 proto kernel scope link src 10.20.23.2 
```

r3's table is now four lines: the default and its three connected networks. **There is no line naming
pc1's network**, and none is needed. Any destination r3 does not own goes to `10.20.13.1`.

The cable from r1 to r2 is still pulled, and the ping that failed in the previous section now works:

```
ana@pc1:~$ ping -c 2 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
64 bytes from 10.20.3.10: icmp_seq=1 ttl=62 time=1.53 ms
64 bytes from 10.20.3.10: icmp_seq=2 ttl=62 time=1.22 ms

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.222/1.373/1.525/0.151 ms
```

The replies carry `ttl=62` where the earlier ones carried `61`. **One router fewer on the way back**: r3
hands them straight to r1 over the spare cable, and r2 is no longer on the path in either direction.

## Where this shape appears

- *A branch office* with one link to head office: a default towards head office, and head office
  holds one route for the branch's block pointing back down that link.
- *A home or small office* behind a provider: a default towards the provider, which is what lesson
  10's DHCP hands every PC as its gateway and what the home router itself holds towards the provider.
- *A provider's customer*: the provider keeps a static route for the customer's block pointing at the
  customer's link, and the customer keeps a default pointing back. Neither side runs a protocol.

**A stub needs only a default; the network around it needs the specific route back.** Both halves are
static, and they are the same pair this lesson typed for pc1 and pc3, with one side collapsed into
`0.0.0.0/0`.

## Where a default goes wrong

**A default route is only safe on a router that really has one exit.** Give two routers defaults that
point at each other, and a packet for a destination neither of them knows bounces between them until its
TTL runs out. Each one hands the packet to the other, sure that the other knows.

That is also why r3's default went over the spare cable to r1 rather than to r2. With the cable from r1
to r2 still pulled, r2 has no route to pc1's network, so a default towards r2 would hand r3's replies to
a router that could only answer `!N`. **Choosing where the default points is the one routing
decision a stub makes**, and it has to be made knowing what lies behind the next hop.

The pattern this lesson ends with is the one that survives in practice: a stub at the edges with a
single default, a specific route back towards it from the core, and a routing protocol in the middle
wherever there is more than one way to go. Lesson 16 starts on the middle.
