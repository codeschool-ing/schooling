---
title: The election and the advertisements
version: 1
---

Both routers were started with `state BACKUP`, `hq2` about a second before `hq`, and left to sort
themselves out. A few seconds later, one of them holds two addresses and the other holds one:

```
ana@hq:~$ ip -br addr show eth0
eth0@if1238      UP             192.168.10.2/24 192.168.10.1/24 
ana@hq2:~$ ip -br addr show eth0
eth0@if1240      UP             192.168.10.3/24 
ana@hq:~$ grep -E "STATE|Entering" /run/keepalived.log
Mon Sep 28 18:10:55 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:59 2026: (office) Entering MASTER STATE
ana@hq2:~$ grep -E "STATE|Entering" /run/keepalived.log
Mon Sep 28 18:10:54 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:58 2026: (office) Entering MASTER STATE
Mon Sep 28 18:10:59 2026: (office) Entering BACKUP STATE
```

**`hq` holds `192.168.10.2`, its own, and `192.168.10.1`, the virtual one.** `hq2` has only its own. The
two logs tell how they got there, and they read best side by side.

`hq2` started at 18:10:54 as a backup and heard nothing. `hq` started at 18:10:55 and did the same, and
for a few seconds two backups listened to each other's silence. `hq2`'s wait ran out first, because it had
started first: at 18:10:58 it concluded that no master existed and became master itself. A second later
`hq`'s wait ran out too, and it had never heard anybody with a priority above its own 150, so at 18:10:59
it became master, and `hq2`, now hearing 150 against its own 100, went back to being a backup in the same
second. For about a second the office's gateway was `hq2`, and nobody on the LAN would have noticed.

Neither router took over the instant it started. **A router that has just started waits to hear whether
a master already exists**, because taking the address first and asking afterwards is how two routers end
up answering for it at once. The log's clock counts whole seconds, and it shows four of them between
starting and becoming master on both.

## The heartbeat on the wire

The master tells the LAN it is alive by sending an **advertisement**, once every `advert_int`. The laptop
can see them, because they go to a multicast group every host on the segment receives:

```
ana@laptop:~$ sudo tcpdump -n -t -i eth0 -c 3 vrrp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Each line is one advertisement: from `hq`'s own address, `192.168.10.2`, to `224.0.0.18`, the group
reserved for VRRP. It names the group, `vrid 10`, the sender's priority, `prio 150`, and the interval,
`intvl 1s`. The backup does nothing with them except restart a timer each time one arrives. `hq2`
sends none at all: **only the master speaks**, and silence from the master is the only thing that
makes a backup act.

That silence has a length, the **master down interval**: three advertisement intervals plus a skew
that depends on the backup's own priority, (256 − priority) / 256 of a second. For `hq2`, at 100, that is
3 + 156/256, about 3.61 seconds. The skew is there for LANs with several backups: the one with the highest
priority has the shortest wait, so it speaks first and the others hear it and stay quiet.

`authtype none` is worth a second look. Nothing in the advertisement proves it came from a router, and a
host on the LAN that sent advertisements with a higher priority would become the office's gateway.
VRRPv3 dropped authentication altogether, on the grounds that a password sent in clear on the same LAN
protected nothing. **The defence is keeping untrusted machines off the routers' segment**: the routers
on their own VLAN, or switch filters that accept VRRP only from the routers' ports.

## Which hardware address the hosts learn

The laptop sends to `192.168.10.1`, so it has to learn a hardware address for it. After one ping:

```
ana@laptop:~$ ip -br link show dev eth0; ping -c 1 -q 192.168.10.1 >/dev/null; ip neigh show 192.168.10.1
eth0@if1244      UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:02 DELAY 
```

The laptop's own MAC ends in `:14`, and it has learnt `52:54:00:a8:0a:02` for the gateway, which is
`hq`'s own hardware address. The standard intends something else: a **virtual MAC**, `00-00-5E-00-01-`
followed by the VRID in hex, here it would be `00:00:5e:00:01:0a`, owned by whichever router is master,
so that a failover never changes the hosts' ARP entries at all. keepalived can do that, with an option
called `use_vmac`, and this lab does not use it. **In keepalived's default mode the new master has to tell
every host that the address has moved**, and the next two sections watch it doing so.
