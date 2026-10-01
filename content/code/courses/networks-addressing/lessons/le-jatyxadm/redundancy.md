---
title: Redundancy, a second path already in the table
version: 1
---

**Redundancy** means two of whatever many people depend on: two cables, two routers, two power
supplies. The wrong idea about it is that a spare is redundancy. A spare router in a box, or a backup
cable nobody has ever sent traffic over, is a plan for a long outage. Redundancy that matters is the
second path **already in use, or already in the routing table**, so that the failure of the first
costs nothing.

In the campus, each distribution router has a cable to both cores. Ask d1 how it reaches pc2's LAN:

```
root@d1:~# ip route show 10.20.12.0/24
10.20.12.0/24 nhid 24 proto ospf metric 20 
	nexthop via 10.20.0.5 dev eth1 weight 1 
	nexthop via 10.20.0.13 dev eth2 weight 1 
```

**One route, two next hops**: through `10.20.0.5` (c1) on `eth1`, and through `10.20.0.13` (c2) on
`eth2`, each with `weight 1`. OSPF found two paths of equal cost and installed both, so d1 spreads
its traffic across the two cores. This is called **equal-cost multipath**, and the traceroute in the
previous section, which went through c2, took one of the two.

## The cut

pc1 starts twenty pings, one every half second. While they run, the cable from d1 to c2 is cut — d1's
`eth2` set down. The ping finished after the cut, so its summary is printed after the command that
cut the cable:

```
root@d1:~# ip link set eth2 down
ana@pc1:~$ ping -c 20 -i 0.5 -q 10.20.12.22
PING 10.20.12.22 (10.20.12.22) 56(84) bytes of data.

--- 10.20.12.22 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 9532ms
rtt min/avg/max/mdev = 0.842/1.203/2.074/0.308 ms
```

**20 transmitted, 20 received, 0% packet loss.** Compare lesson 3's ring, which lost 19 of 30 to the
same kind of cut. There, the second path had to be discovered after the first one died. Here it was
already in d1's table, and all d1 had to do was stop using one of its two next hops:

```
root@d1:~# ip route show 10.20.12.0/24
10.20.12.0/24 nhid 20 via 10.20.0.5 dev eth1 proto ospf metric 20 
ana@pc1:~$ traceroute -n 10.20.12.22
traceroute to 10.20.12.22 (10.20.12.22), 30 hops max, 60 byte packets
 1  10.20.11.1  1.090 ms  0.592 ms  0.466 ms
 2  10.20.0.5  0.332 ms  0.283 ms  0.284 ms
 3  10.20.0.10  0.610 ms  0.448 ms  0.390 ms
 4  10.20.12.22  0.372 ms  0.583 ms  0.551 ms
```

The route now has a single next hop, `10.20.0.5` through `eth1`, and pc1's packets go up to c1
(`10.20.0.5`) and down to d2 (`10.20.0.10`, d2's end of the c1–d2 cable). Same length as before,
through the other core.

Be honest about what one run shows: these twenty pings were lucky enough, or the cut quick enough,
that none fell into the gap. A real network can lose a packet or two during the same change. What
does not depend on luck is the shape: **the alternative did not have to be found, so it could not be
slow to find**.

## Redundancy that is not

Three ways a design looks redundant on paper and is not:

- **Shared fate.** Two cables in the same duct are cut by the same digger. Two routers on the same
  power strip go dark together. Redundancy is only as independent as the least obvious thing the two
  halves share.
- **A path nobody uses.** A backup link that carries no traffic for a year may be broken, misconfigured
  or unplugged on the day it is needed, and nothing says so. Equal-cost paths avoid this by keeping
  both halves busy; a standby link should at least be tested on a schedule.
- **Half the capacity.** With both cores in use, each carries half the load. If one fails, the other
  carries everything. A design where each core runs at 70% is redundant in the drawing and overloaded
  in the failure.

The price is the obvious one — twice the cables and twice the core routers — and the less obvious one:
**more paths are more to understand**. A routing table with two next hops is harder to read by eye
than one with one, which is a reason to keep the redundancy where the design says it is and nowhere
else.
