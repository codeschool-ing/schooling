---
title: Two VLANs, and no way between them
version: 2
---

Lesson 19 split a network into VLANs and showed each one sealed off from the other. That was the
point, and sooner or later it is also the problem: the warehouse needs the file server that lives
in the office VLAN, and every department needs the printers. **A switch configured with VLANs
cannot pass traffic from one VLAN to another on its own**, however obvious the path looks on the
diagram, because each VLAN is a separate broadcast domain and, by the convention lesson 19 followed,
a separate IP subnet. Traffic between subnets is a router's job, which lessons 14 and 15 covered.

The lab for this lesson is one switch, sw1, configured the way lesson 19 left its switches. pc1 and
a web server, srv, are in VLAN 10, in 10.20.10.0/24; pc2 is in VLAN 20, in 10.20.20.0/24. A router,
r1, is plugged into port p8, and p8 is a trunk carrying both VLANs. r1 has no address yet. Every PC
already names a default gateway: 10.20.10.1 for the machines in VLAN 10 and 10.20.20.1 for pc2. Save
it as `~/netlab/intervlan.sh` and build it with `sudo bash ~/netlab/netlab.sh up intervlan`:

```bash
# ~/netlab/intervlan.sh: one switch with two VLANs configured, and a router on
# port p8, which is a trunk carrying both. The router has no address yet.
#
#   pc1 (VLAN 10, 10.20.10.21) --p1\
#   srv (VLAN 10, 10.20.10.10) --p3-- sw1 --p8 (trunk: 10, 20)-- r1
#   pc2 (VLAN 20, 10.20.20.22) --p2/
node pc1; node pc2; node srv; node sw1; node r1 router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link srv eth0 sw1 p3; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p3 p8" vlan_filtering 1
local p
for p in p1 p3; do ip netns exec sw1 bridge vlan add dev $p vid 10 pvid untagged; ip netns exec sw1 bridge vlan del dev $p vid 1; done
ip netns exec sw1 bridge vlan add dev p2 vid 20 pvid untagged; ip netns exec sw1 bridge vlan del dev p2 vid 1
ip netns exec sw1 bridge vlan add dev p8 vid 10; ip netns exec sw1 bridge vlan add dev p8 vid 20
addr pc1 eth0 10.20.10.21/24; addr srv eth0 10.20.10.10/24; addr pc2 eth0 10.20.20.22/24
gw pc1 10.20.10.1; gw srv 10.20.10.1; gw pc2 10.20.20.1
web srv 10.20.10.10
```

The `bridge vlan` lines are lesson 19's commands: `pvid untagged` makes a port an access port in that
VLAN, and p8, given both VLANs without that word, is the trunk. `node r1 router` switches forwarding
on, and nothing else on r1 is configured.

```
root@sw1:~# bridge vlan show
port              vlan-id  
p1                10 PVID Egress Untagged
p2                20 PVID Egress Untagged
p3                10 PVID Egress Untagged
p8                1 PVID Egress Untagged
                  10
                  20
br0               1 PVID Egress Untagged
```

p1 and p3 (pc1 and srv) are access ports in VLAN 10, p2 (pc2) is an access port in VLAN 20, and p8
carries 10 and 20 tagged, with VLAN 1 untagged as lesson 19 warned. Now pc1 tries both of its
neighbours:

```
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 10.843/10.843/10.843/0.000 ms
ana@pc1:~$ ping -c 1 -W 1 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@pc1:~$ ip neigh
10.20.10.1 dev eth0 INCOMPLETE 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

srv answers, because it is in the same VLAN and the same subnet: pc1 asked for its MAC, got it, and
the neighbour table keeps it as `REACHABLE`. pc2 does not. pc1 compared 10.20.20.22 with its own
/24, saw another subnet, and did what lesson 14 says a host does: it sent the packet to its default
gateway. To do that it needed the gateway's MAC, so it asked for 10.20.10.1 — and **the entry
`10.20.10.1 dev eth0 INCOMPLETE` is the whole diagnosis: pc1 asked who has its gateway's address,
and nobody in VLAN 10 owns it yet.**

Notice what the switch did and did not do. pc2's frames would have had to cross from VLAN 10 into
VLAN 20 somewhere inside sw1, and a switch only ever delivers a frame within the VLAN it arrived
in. No setting on the access ports changes that, and even a switch that did carry the frame
across would not be asked to: pc1 believes pc2 is in another subnet, so it will only ever send to
its gateway.

So between VLANs there has to be a router, and there are three ways to give it the VLANs. The plain
one is a router with one port and one cable per VLAN: correct, and it costs a router port and a
switch port per VLAN, which stops being reasonable somewhere around a handful of them. The next two
sections build the second way, a router with one port on a trunk, and the section after them
builds the third, where the routing moves inside the switch.
