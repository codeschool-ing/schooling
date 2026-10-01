---
title: "Access ports: one VLAN, and the PC never knows"
version: 1
---

A common picture is that a PC is "configured for VLAN 10". In the usual case nothing on the PC
changes at all. **An access port belongs to one VLAN, and the VLAN is a property of the port, not
of the machine plugged into it.** The PC sends an ordinary Ethernet frame; the switch decides
which VLAN the frame is in from the port it arrived on, and hands frames out to the PC as ordinary
frames again. Move the cable to another port and the PC is in another VLAN, with the same address
and the same configuration.

On sw1, pc1's port goes into VLAN 10 and pc2's into VLAN 20:

```
root@sw1:~# bridge vlan add dev p1 vid 10 pvid untagged
root@sw1:~# bridge vlan add dev p2 vid 20 pvid untagged
root@sw1:~# bridge vlan del dev p1 vid 1
root@sw1:~# bridge vlan del dev p2 vid 1
```

Three words do the work in the first line. `vid 10` makes p1 a member of VLAN 10. `pvid` makes
VLAN 10 the one an untagged frame arriving on p1 is put in. `untagged` makes frames of VLAN 10
leave p1 without a tag. **Member, untagged on the way in, untagged on the way out: that is an
access port**, and a Cisco switch says it as `switchport mode access` and `switchport access vlan
10`. The two `del` lines take p1 and p2 out of VLAN 1; without them each port would be in two
VLANs, and a port in two VLANs is not an access port any more.

sw2 got the same treatment, written as a loop: p1 (pc3) into VLAN 10, and p2 and p3 (pc4 and
pc5) into VLAN 20. Then sw1's table:

```
root@sw2:~# for p in p1; do bridge vlan add dev $p vid 10 pvid untagged; bridge vlan del dev $p vid 1; done
root@sw2:~# for p in p2 p3; do bridge vlan add dev $p vid 20 pvid untagged; bridge vlan del dev $p vid 1; done
root@sw1:~# bridge vlan show
port              vlan-id  
p1                10 PVID Egress Untagged
p2                20 PVID Egress Untagged
p24               1 PVID Egress Untagged
br0               1 PVID Egress Untagged
```

p1 is in 10, p2 in 20, and both are `PVID Egress Untagged` in their own VLAN. p24, the cable to
sw2, was not touched and is still in VLAN 1 alone. Now pc1 pings pc3, which is in the same VLAN
at the other end of the lab:

```
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1021ms

```

**Two transmitted, none received, and nothing is broken in the usual sense**: every cable is in,
every interface is up, and both PCs are in VLAN 10. Follow pc1's frame. It enters sw1 on p1 and
is put in VLAN 10. sw1 looks for the ports in VLAN 10 that it could send the frame out of, and p1
is the only one: p24 is in VLAN 1. The frame has nowhere to go, and the switch drops it. **A VLAN
exists only on the ports that are members of it, and the cable between two switches is a port at
each end.**

Nothing reports the drop. A switch working at layer 2 has no error message to send — ICMP, from
the networks course, belongs to routers and hosts — so the PC sees exactly what it would see if
the cable were cut: questions with no answers. That silence is what makes VLAN faults slow to find,
and lesson 22 ends with a checklist built around it.

Two ways out are possible. One is a cable per VLAN between the switches: p23 for VLAN 10, p24 for
VLAN 20. It works, and it stops working at scale, because twenty VLANs between two switches would
cost twenty cables and forty ports. The other is one cable that carries every VLAN and says, on
each frame, which VLAN it belongs to. That is a trunk, and it is the next section.
