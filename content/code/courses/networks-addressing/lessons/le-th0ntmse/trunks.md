---
title: "Trunks: several VLANs on one cable"
version: 1
---

**A trunk is a port that belongs to several VLANs at once and marks every frame with the VLAN it
belongs to**, so that the switch at the other end can put each frame back in the right one. It is
the same cable as before; what changes is the agreement between its two ends about what the frames
on it mean.

On sw1, p24 joins VLANs 10 and 20:

```
root@sw1:~# bridge vlan add dev p24 vid 10
root@sw1:~# bridge vlan add dev p24 vid 20
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 PVID Egress Untagged
                  10
                  20
```

Compare the words with an access port's. There is no `pvid` and no `untagged` on 10 or 20, so
frames of those VLANs leave p24 **tagged**, carrying their VLAN number with them. VLAN 1 is still
there as `PVID Egress Untagged`: this trunk carries one VLAN without a tag and two with one. The
untagged VLAN on a trunk has a name and a set of mistakes of its own, and it gets the section after
next. sw2's p24 received the same two commands, which the lesson does not repeat.

Both departments now reach their other half, across the same cable:

```
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.946/3.571/6.196/2.625 ms
ana@pc2:~$ ping -c 2 -q 10.20.20.24
PING 10.20.20.24 (10.20.20.24) 56(84) bytes of data.

--- 10.20.20.24 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.886/2.277/3.668/1.391 ms
```

Two transmitted and two received, in VLAN 10 from pc1 to pc3 and in VLAN 20 from pc2 to pc4. The
separation still holds: a broadcast from pc1 crosses the trunk marked as VLAN 10, and sw2 delivers
it only to its ports in VLAN 10. The last section puts a machine in VLAN 20 and shows it hearing
nothing.

**A trunk carries only the VLANs it is a member of.** On the Linux bridge that list is explicit,
and VLAN 30 would not cross p24 until somebody added it at both ends. Some commercial switches
start the other way round, allowing every VLAN on a trunk until told otherwise; writing the list
out by hand means a VLAN exists only where it was meant to exist, and a broadcast storm in one VLAN
stays off the cables that have no business carrying it.

Trunks appear wherever one cable has to serve more than one VLAN. Between switches, as here. Between
a switch and a router that routes between VLANs, which is lesson 22. Between a switch and a server
running virtual machines that belong to different VLANs, where the server's own software takes the
tags off. And between a switch and a Wi-Fi access point that offers a staff network and a guest
network, each mapped to its own VLAN — the lab has no radio, so that last one is described rather
than run.

One warning about the word. Most vendors call this a trunk, and Cisco configures it with
`switchport mode trunk`. **Some vendors, HP's switches among them, call this a tagged port and use
"trunk" for two cables bundled into one**, which this course calls link aggregation in lesson 21.
When a document from another vendor says trunk, check which of the two it means before following
it.
