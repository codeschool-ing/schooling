---
title: "The bridge: what a switch is underneath"
version: 1
---

Before switches, an Ethernet that had grown too busy was cut in two and the halves were joined by a
**bridge**. A bridge had two ports, one per half. **It learnt which MAC addresses lived on which side,
by reading the source address of every frame, and passed a frame across only when its destination
was on the other side.** Traffic between two machines on the same half stayed on that half.

That description is lesson 1's switch, word for word, with two ports instead of many. **A switch is
a bridge with many ports**, built to forward in hardware; the standards still call the mechanism
bridging, and Linux calls it a bridge. The lab's switch, sw1, is a Linux bridge named `br0` with
five ports:

```
root@sw1:~# bridge link show
77: p1@if78: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
79: p2@if80: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
81: p3@if82: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
83: p4@if84: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
85: p8@if86: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# bridge fdb show br br0 dynamic
```

Five ports, `master br0`, and an empty table of learnt addresses. The lab emptied it just before
this block, so you can watch it learn. pc1 pings the server, then pc2 does:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.213/1.213/1.213/0.000 ms
ana@pc2:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.229/1.229/1.229/0.000 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:fd:f2:d2:63:ba dev p2 master br0 
02:9e:43:3e:ca:ae dev p4 master br0 
```

**Three entries, from two pings.** pc1's frames taught the bridge that `02:25:70:bc:29:c6` is on p1;
pc2's taught it that `02:fd:f2:d2:63:ba` is on p2; and the server, which answered both, taught it
that `02:9e:43:3e:ca:ae` is on p4. Nobody typed any of it. pc3 and the router on p8 sent nothing in
that time, so the bridge knows nothing about them yet.

`fdb` stands for *forwarding database*, the bridge's name for its table, and `dynamic` asks for the
entries it learnt rather than ones somebody configured.

## Entries expire

```
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 30000
```

**`ageing_time 30000` is in hundredths of a second: 300 seconds, five minutes.** An entry that no
frame has refreshed for that long is forgotten, so a machine unplugged from p1 and plugged into p3
is found in its new place as soon as it sends one frame, and an address that has gone away stops
taking a line in the table. Lesson 1 set this to 0 to make the switch forget everything at once,
which is how it imitated a hub.

## What a bridge divides, and what it does not

A bridge sits between two segments and **splits them into separate collision domains**: a
collision on one side never reaches the other, because the bridge receives a whole frame before
sending it on. It does **not** split the broadcast domain. A frame to `ff:ff:ff:ff:ff:ff`, such as
ARP's question, is for everybody, so the bridge sends it out of every port, and the two halves are
still one network with one range of addresses. Lesson 18 measures both, and lesson 19 shows how a
switch divides a broadcast domain without a router.

Linux bridges are not only a lab trick. Virtual machines and containers on one host reach the
network through exactly this kind of bridge, and on many home routers the "switch" ports on the back
are joined by a bridge in the router's software.
