---
title: Two cables that act as one
version: 2
---

The link between two switches carries everybody's traffic at once: every PC on one side talking to
every server on the other. When it fills up, or when its one cable is pulled, the whole floor
notices. The obvious answer is a second cable, and lesson 20 showed what a second cable does on its
own. **With spanning tree off, two cables between two switches are a loop. With spanning tree on,
one of them is blocked**, and it carries nothing until the other one fails, and then only after
half a minute of listening and learning.

**Link aggregation** is the third option. It tells both switches that the cables between them are
one logical port. Spanning tree, the MAC table and everything else above see a single link, so there
is no loop to break and nothing to block. Underneath, traffic is spread across the cables, and
losing one of them reduces the capacity instead of cutting the link.

The idea has a different name on almost every system you meet:

| where | what it is called |
| --- | --- |
| the IEEE standard | link aggregation, a LAG (*link aggregation group*) |
| Cisco switches | EtherChannel, or a port channel |
| Linux | a bond, with the cables as its members |
| Windows servers | NIC teaming |

All of them describe the same arrangement. **The protocol that lets the two ends agree on it is
LACP**, the subject of the next section.

## The lab: two switches, two spare cables

The lab for this lesson is two switches, `sw1` and `sw2`, joined by two cables, `e1` and `e2` at
each end. `pc1` is on `sw1`; `pc2`, `pc3` and `pc4` are on `sw2`, with addresses `10.20.10.21`
to `10.20.10.24`. Save it as `~/netlab/lag.sh` and build it with `sudo bash ~/netlab/netlab.sh up lag`:

```bash
# ~/netlab/lag.sh: two switches joined by two cables, e1 and e2, that are not
# yet part of either switch. pc1 is on sw1; pc2, pc3 and pc4 on sw2.
#
#   pc1 -- sw1 ==(e1, e2)== sw2 -- pc2, pc3, pc4
local n
for n in sw1 sw2 pc1 pc2 pc3 pc4; do node $n; done
link sw1 e1 sw2 e1; link sw1 e2 sw2 e2
link pc1 eth0 sw1 p1; link pc2 eth0 sw2 p1; link pc3 eth0 sw2 p2; link pc4 eth0 sw2 p3
switch sw1 "p1"; switch sw2 "p1 p2 p3"
addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24
addr pc3 eth0 10.20.10.23/24; addr pc4 eth0 10.20.10.24/24
```

The two `link sw1 e… sw2 e…` lines lay the cables, and neither `e1` nor `e2` is in the list of ports
either `switch` line is given. So at the start the two cables are plugged in and up, but neither has
been made part of either switch:

```
root@sw1:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
e1@if485         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,UP,LOWER_UP> 
e2@if487         UP             02:ce:7c:39:59:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p1@if490         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 1ms

```

`br0` is the switch itself and `p1` is `pc1`'s port. **`e1` and `e2` are `UP` with a signal
(`LOWER_UP`), and still `pc1` cannot reach `pc2`**: a cable with a signal is not a path until the
switch forwards frames onto it, and these two belong to no bridge yet. That is the state of a new
cable on a managed switch too. Plugging it in is half the job, and the configuration is the other
half.

## What aggregation does not give you

It is tempting to read two 10 Gb/s cables as one 20 Gb/s link. **The total is right and the
single-flow figure is not.** A LAG decides, conversation by conversation, which member carries it,
and a conversation stays on its member; the hashing section of this lesson shows how, and shows the
counters. So one large file copy between two machines runs at the speed of one cable, and the
second cable helps only when there are other conversations to carry.

Aggregation is also a matter between two neighbours. The cables of one LAG run between the same two
devices, and in this lesson they join two switches. Some vendors let one LAG end on two switches that
behave as one, so that losing a whole switch is survivable too, but that is a design of its own and
not something this lab built.
