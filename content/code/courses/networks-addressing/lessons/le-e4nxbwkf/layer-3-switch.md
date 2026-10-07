---
title: The layer 3 switch, and moving a gateway
version: 2
---

A **layer 3 switch** is a switch that can also route between its own VLANs. The usual description,
"a switch and a router in one box", is close, and the part it leaves out is the useful one: **the
router inside has no cable to the switch at all**. It owns one interface per VLAN, attached directly
to the switch's VLANs, so a packet routed from VLAN 10 to VLAN 20 never leaves the box and never
crosses a trunk twice. Those interfaces are called **SVIs** (*switched virtual interfaces*), and a
Cisco switch writes them `interface Vlan10`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A layer 3 switch, drawn as one box, sw1. Inside, at the top, routing between VLANs. Below it, two switched virtual interfaces: vlan10 with 10.20.10.1 and vlan20 with 10.20.20.1. Both attach directly to br0, the switch itself, which carries VLANs 10 and 20. Outside the box, pc1 at 10.20.10.21 and srv at 10.20.10.10 are on VLAN 10 ports, and pc2 at 10.20.20.22 on a VLAN 20 port. No cable joins the router part to the switch part.\"><defs><marker id=\"v22v-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"158\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sw1, one box</text><line x1=\"300\" y1=\"66\" x2=\"210\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"420\" y1=\"66\" x2=\"510\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"210\" y1=\"120\" x2=\"210\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"510\" y1=\"120\" x2=\"510\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"270\" y=\"34\" width=\"180\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">routing between VLANs</text><rect x=\"120\" y=\"86\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vlan10  10.20.10.1</text><rect x=\"420\" y=\"86\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vlan20  10.20.20.1</text><rect x=\"40\" y=\"136\" width=\"640\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">br0: the switch, carrying VLANs 10 and 20</text><line x1=\"140\" y1=\"168\" x2=\"140\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"60\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pc1  10.20.10.21</text><line x1=\"310\" y1=\"168\" x2=\"310\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"230\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">srv  10.20.10.10</text><line x1=\"580\" y1=\"168\" x2=\"580\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"500\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pc2  10.20.20.22</text></svg>", "caption": "A layer 3 switch. The router inside has one interface per VLAN, attached straight to the switch's own VLANs, so a routed packet never leaves the box."}
```

To make the switch the only router in the lab, r1's end of the cable was set down before this block:
`ip link set eth0 down` at a root prompt on r1. pc1's ping to pc2 fails again, as it should with no router anywhere:

```
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

```

Then sw1 is given an interface in each VLAN, the addresses r1 had, and permission to forward:

```
root@sw1:~# ip link add link br0 name vlan10 type vlan id 10
root@sw1:~# ip link add link br0 name vlan20 type vlan id 20
root@sw1:~# bridge vlan add dev br0 vid 10 self && bridge vlan add dev br0 vid 20 self
root@sw1:~# ip addr add 10.20.10.1/24 dev vlan10 && ip addr add 10.20.20.1/24 dev vlan20
root@sw1:~# ip link set vlan10 up && ip link set vlan20 up && sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
root@sw1:~# ip route
10.20.10.0/24 dev vlan10 proto kernel scope link src 10.20.10.1 
10.20.20.0/24 dev vlan20 proto kernel scope link src 10.20.20.1 
```

`vlan10` and `vlan20` are VLAN interfaces again, the same kind r1 used, built this time on top of
`br0`, the switch itself. The third command matters and is easy to miss: **`br0` has to join VLANs
10 and 20 as well** (`self` means the bridge's own port rather than one of its cables), because in
lesson 19's listings it was only in VLAN 1, and a switch's own interfaces hear only the VLANs the
switch has joined. `sysctl -w net.ipv4.ip_forward=1` is the line that turns a host with two
addresses into a router; r1 had it from the lab, and the switch did not. The routing table has the
same two connected routes r1 had, now on `vlan10` and `vlan20`.

Everything is in place, and the first test fails:

```
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1043ms

ana@pc1:~$ ip neigh show 10.20.10.1
10.20.10.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 STALE 
root@sw1:~# ip -br link show vlan10
vlan10@br0       UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

Two transmitted, none received. **pc1's neighbour table still says that 10.20.10.1 is at
`02:1f:23:e7:e9:d5`, which is r1's MAC**, the one the last two sections watched on the trunk. The
switch's `vlan10` is at `02:6a:dc:93:3b:8a`. So pc1 is doing exactly what its table tells it to:
it sends frames for its gateway to a MAC that nothing on the switch answers to any more. The address
moved to a new machine; the cache of every host in the VLAN did not move with it.

The entry says `STALE`, which means the kernel will check it before trusting it for long, and a
host left alone does correct itself once the check against the old MAC fails. A network does not
have to wait for that. **The new owner of an address announces itself with a gratuitous ARP**: an
ARP message about its own address, sent to the whole VLAN unasked, saying which MAC now holds it.

```
root@sw1:~# arping -U -c 1 -I vlan10 10.20.10.1
ARPING 10.20.10.1 from 10.20.10.1 vlan10
Sent 1 probes (1 broadcast(s))
Received 0 response(s)
ana@pc1:~$ ip neigh show 10.20.10.1
10.20.10.1 dev eth0 lladdr 02:6a:dc:93:3b:8a STALE 
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.041/9.526/18.011/8.485 ms
ana@pc1:~$ traceroute -n 10.20.20.22
traceroute to 10.20.20.22 (10.20.20.22), 30 hops max, 60 byte packets
 1  10.20.10.1  4.508 ms  0.405 ms  0.212 ms
 2  10.20.20.22  1.100 ms  0.477 ms  0.208 ms
```

`arping -U` sends that unsolicited announcement. `Received 0 response(s)` is correct, because
nobody answers an announcement. pc1's table now holds `02:6a:dc:93:3b:8a`, still `STALE`: Linux
records an address it did not ask for but does not mark it confirmed until it uses it. The next
ping goes through, and the traceroute shows the same two hops as before, with **10.20.10.1 now
answering from inside the switch**.

Any change that moves a gateway address to a different MAC, including swapping a failed router for
a spare, meets the same stale caches. First-hop redundancy protocols such as VRRP avoid the problem
by design: the gateway address keeps one virtual MAC whichever router holds it, so no host's cache
goes stale, and the router taking over sends a gratuitous ARP so that the switches learn which port
that MAC now lives behind.

What the lab cannot show is speed. A commercial layer 3 switch routes between VLANs in its
forwarding hardware, at close to the speed it switches; the Linux bridge here routes in the same
kernel as everything else, and the times in its captures say nothing about real equipment.
