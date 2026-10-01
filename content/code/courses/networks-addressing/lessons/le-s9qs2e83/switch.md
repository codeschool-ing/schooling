---
title: "The switch: one port for each address"
version: 1
---

The common picture of a switch is a power strip for network cables: plug things in and they can all
talk. That is true, and it hides the switch's whole job. **A switch sends each frame out of the one
port where its destination lives, and it learns where everybody lives by reading the source
address of every frame that arrives.** Nobody configures that list. It starts empty and fills
itself.

The lab's switch is sw1. Its ports are named after the machines cabled to them: p1 is pc1's, p2 is
pc2's, p3 is pc3's, p4 is the server's and p8 is the router's. Before anything is sent, the switch
lists its ports and its table of learnt addresses:

```
root@sw1:~# bridge link show
23: p1@if24: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
25: p2@if26: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
27: p3@if28: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
29: p4@if30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
31: p8@if32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# bridge fdb show br br0 dynamic
ana@pc1:~$ ping -c 2 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=6.62 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=1.61 ms

--- 10.20.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.607/4.111/6.616/2.504 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:fd:f2:d2:63:ba dev p2 master br0 
```

Read it in four steps. `bridge link show` lists five ports, all `UP,LOWER_UP` (a cable with
something live at the other end) and all in `state forwarding`. The first `bridge fdb show` prints
nothing: **the table of learnt addresses, the forwarding database, is empty**. Then pc1 pings pc2
twice, and the table has two lines:

- `02:25:70:bc:29:c6 dev p1` is pc1's card, learnt when pc1's first frame came in on port 1;
- `02:fd:f2:d2:63:ba dev p2` is pc2's, learnt from pc2's answer on port 2.

The first round trip took 6.62 ms and the second 1.61 ms. Part of the difference is that the first
ping also had to find pc2's MAC address with ARP, because the lab emptied every table before this
block. The rest is this lab, which runs every machine on one virtual computer and is no guide to
how fast a real cable is.

The table is what keeps a conversation private to the two ports in it. To see that, pc3 runs
`tcpdump` while pc1 pings pc2 three more times. tcpdump was started first and printed its report
when it stopped, six seconds later, so it appears after the ping:

```
ana@pc1:~$ ping -c 3 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=0.829 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=0.922 ms
64 bytes from 10.20.10.22: icmp_seq=3 ttl=64 time=0.693 ms

--- 10.20.10.22 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2006ms
rtt min/avg/max/mdev = 0.693/0.814/0.922/0.094 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

Three requests and three replies crossed the switch, and **pc3 saw `0 packets captured`**. The
switch knew that pc2 was on p2 and pc1 on p1, so no frame of that conversation was ever sent out of
p3. Nothing on pc3 had to ignore anything: the frames never reached its cable.

Two consequences follow, and both come back in lesson 18, which is about nothing else:

- **Each port of a switch is its own segment.** pc1 talking to pc2 and pc3 talking to the server
  can happen at the same moment, on different ports, without waiting for each other.
- **A frame to an address the switch has not learnt yet goes out of every port.** The table only
  helps once the destination has sent something. Until then, and for broadcasts such as ARP's
  question, the switch floods, and lesson 18 measures exactly when.

A switch reads layer 2 and nothing above it. It does not know that 10.20.10.22 is an IP address,
which is why every machine on sw1 has an address in the same network, 10.20.10.0/24: to reach any
other network, a frame has to be addressed to a router, which is two sections on.
