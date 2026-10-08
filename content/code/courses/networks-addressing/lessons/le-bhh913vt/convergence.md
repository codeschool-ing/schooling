---
title: Convergence: the failure with the light still on
version: 2
---

**Convergence** is the time between something changing and every router agreeing on the new paths. Until
it finishes, some packets go towards a path that no longer works, and they are lost.

The easy failure is a pulled cable. The interface loses its signal, the router sees it at once, as r1 did
in lesson 15, and OSPF recalculates within moments. **The hard failure is the one that leaves the signal
up**: a media converter, or a switch between two routers, dies while still powering its port, and the
cable looks perfect from both ends. The lab staged that between r1 and r4, with rules on r1 that drop
every frame on `eth4` in both directions. The interface stays up; nothing gets through. These are the
rules, typed at a root prompt on r1, and `nft delete table netdev cut; nft delete table inet cutout`
removes them:

```sh
nft add table netdev cut
nft add chain netdev cut in "{ type filter hook ingress device eth4 priority 0; policy drop; }"
nft add table inet cutout
nft add chain inet cutout out "{ type filter hook output priority 0; }"
nft add rule inet cutout out oifname eth4 drop
nft add chain inet cutout fwd "{ type filter hook forward priority 0; }"
nft add rule inet cutout fwd oifname eth4 drop
```

A ping from pc1 to pc2 was started first, one packet a second for 70 seconds, and the cut came two
seconds into it. Twenty seconds after the cut, r1 still believed in r4:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          46.216s           35.402s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.20.0.13        1 Full/-          46.223s            8.651s 10.20.0.13      eth4:10.20.0.14                      2     0     0

```

r4, `10.20.0.13`, is still `Full`, with **`8.651s`** left on its dead timer: hellos stopped arriving
when the frames did, and the countdown that started at 40 seconds is nearly done. `RXmtL 2` is r1's
retransmission list, two updates it has sent r4 and is still waiting to hear acknowledged. Until the timer
runs out, r1's table still sends pc1's traffic to r4, and every packet is lost.

Meanwhile pc1's ping ran to the end, and printed its summary:

```
ana@pc1:~$ ping -c 70 -i 1 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
70 packets transmitted, 40 received, +21 errors, 42.8571% packet loss, time 69901ms
rtt min/avg/max/mdev = 0.434/1.257/4.335/0.694 ms, pipe 3
```

**70 sent, 40 answered.** The other 30 were lost, and ping counted 21 error messages along the way. At one
packet a second, that is **about 30 seconds without a path** between pc1 and pc2, and almost all of it is
the dead interval being waited out. The SPF calculation itself, once it ran, was not what took the time.

Afterwards r4 is gone from the list, and traffic takes the only path left, the expensive direct cable:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          1m34s             36.799s 10.20.0.2       eth1:10.20.0.1                       0     0     0

ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.854 ms  0.201 ms  0.375 ms
 2  10.20.0.2  0.263 ms  0.210 ms  0.388 ms
 3  10.20.2.10  0.181 ms  0.154 ms  0.104 ms
```

## Making it faster

**The dead interval is the convergence time for a silent failure**, so the lever is the timers. Lesson 3's
ring ran OSPF with a hello every second and a dead interval of four seconds, which is why a broken cable
there was noticed in four seconds instead of forty. The price is more hellos on every link and a greater
chance of declaring a busy neighbour dead when it was only slow to answer, and the timers have to match on
both ends of each link.

The usual answer on real networks is **BFD** (*Bidirectional Forwarding Detection*), which lesson 15
named: a separate, very light protocol that exchanges hellos many times a second and tells OSPF the
moment a neighbour stops answering, so OSPF's own timers can stay at their defaults. It was not run in this
lab.

The arithmetic to keep: **a failure that drops the signal costs the time to recalculate; a failure that
keeps the signal costs the dead interval first.** When you design for redundancy, it is the second number
that tells you how long the redundancy takes to work.
