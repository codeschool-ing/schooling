---
title: Electing a root
version: 1
---

**Spanning tree turns a web of cables into a tree**: one path between any two switches, and no
loops. It does it without unplugging anything. Every cable stays connected, and on each redundant
one a single port is put into a state where it forwards no data. If a cable in use fails, a blocked
port can take over. The protocol is the **Spanning Tree Protocol** (STP), standardised as
IEEE 802.1D, and the Linux bridge in this lab implements that original version.

The switches talk to each other in **BPDUs** (*bridge protocol data units*), small frames sent to a
multicast address that every STP switch listens to. By default a switch sends one every 2 seconds,
the *hello time*. Out of those messages comes, in order:

1. **one root bridge** for the whole network, the switch every path is measured from;
2. on every other switch, **one root port**, its cheapest way towards the root;
3. on every cable, **one designated port**, the end that forwards traffic on that cable;
4. every port left over **blocks**.

This section is the first step. The next one is the other three.

## Switching it on

Spanning tree was switched on in all three switches, and the cable from `sw3` to `sw1`, the one that
caused the storm, was plugged back in. Straight away, `sw1` was cautious about it:

```
root@sw1:~# ip link set br0 type bridge stp_state 1
root@sw2:~# ip link set br0 type bridge stp_state 1
root@sw3:~# ip link set br0 type bridge stp_state 1
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state listening priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
```

`p3` has a signal again (`LOWER_UP`) and is in `state listening`: it exchanges BPDUs and forwards no
data while the election runs. Forty seconds later, the three switches had agreed:

```
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw3:~# bridge link show
463: p2@if464: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
466: p1@if465: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
471: p10@if472: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.643/4.118/6.594/2.475 ms
```

Eight ports forward and **one blocks: `p3` on `sw2`, its end of the cable to `sw3`**. The triangle is
now a line, `sw2`–`sw1`–`sw3`, and `pc1` reaches `pc3` with no storm. Nothing on the PCs changed.

## The bridge ID, and why the lowest wins

Every switch has a **bridge ID**: a 2-byte priority followed by a MAC address of the switch. The
kernel keeps all of it in files:

```
root@sw1:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.026adc933b8a
root_id:8000.026adc933b8a
root_port:0
root_path_cost:0
root@sw2:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.02e0779de790
root_id:8000.026adc933b8a
root_port:1
root_path_cost:2
root@sw3:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.02a59d312a8c
root_id:8000.026adc933b8a
root_port:1
root_path_cost:2
```

Read `8000.026adc933b8a` as two parts. `8000` is the priority in hexadecimal, **32768, the default**,
and every switch here has it. After the dot comes the MAC address without its colons. Each switch
starts by claiming to be the root itself, and **the lowest bridge ID wins**: compare the priorities
first and, when they tie, the MAC addresses. All three priorities are equal, so the MACs decide, and
`02:6a:…` is lower than `02:a5:…` and `02:e0:…`. Every switch now gives the same answer for
`root_id`, which is `sw1`'s own ID.

`sw1` is the root, so it has no root port (`root_port:0`) and its distance to the root is
`root_path_cost:0`. The other two reach it through their port number 1, at a cost of 2. **Cost is
added up per port along the path**, and every port in this lab costs 2 (the `cost 2` at the end of
each `bridge link show` line), so 2 means one cable away.

## The root nobody chose

It is tempting to think the root is the biggest or most central switch. **With default priorities,
the root is whichever switch has the lowest MAC address**, and nothing about a MAC says the switch
behind it is fast or well placed. An old access switch in a cupboard can win the election, and then
the whole network's traffic shapes itself around that cupboard. The failover section of this lesson
moves the root by changing a priority, which is how a network chooses its root on purpose.
