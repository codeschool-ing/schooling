---
title: When one VLAN cannot reach its gateway
version: 1
---

Faults between VLANs are hard to find for the reason lesson 19 named: a switch drops a frame from a
VLAN it was not told about and says nothing. The PC sees a ping with no answer, which is also what a
dead router, a wrong address and an unplugged cable look like. **The way through is to follow the
packet in the order it travels and check one thing at each step**, instead of guessing which step
it is.

This fault was staged while r1 was still the router on a stick, before the switch took over: VLAN 20
taken off the trunk, the kind of slip that happens when somebody edits a trunk's list and types it
whole instead of adding to it.

```
root@sw1:~# bridge vlan del dev p8 vid 20
ana@pc2:~$ ping -c 2 -W 1 -q 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1057ms

ana@pc2:~$ ip neigh
10.20.20.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 REACHABLE 
```

pc2 cannot reach its own gateway: two transmitted, none received. And its neighbour table says
`REACHABLE`, with r1's MAC, which looks like a contradiction and is not. **A neighbour entry records
what was true when it was last confirmed**, and this one had been confirmed by the earlier traffic through
r1, before the trunk changed; the kernel has no reason to ask again yet. The table is history
and the ping is the test. Then the switch:

```
root@sw1:~# bridge vlan show dev p8
port              vlan-id  
p8                1 PVID Egress Untagged
                  10
root@sw1:~# bridge vlan add dev p8 vid 20
ana@pc2:~$ ping -c 2 -q 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.961/1.060/1.159/0.099 ms
```

p8 lists 1 and 10, and 20 is gone. Adding it back makes the gateway answer again, two of two.

## A checklist, in the order the packet travels

When a machine in one VLAN cannot reach another VLAN, ask these in order, and stop at the first that
fails:

1. Is the host's own configuration right? Its address and mask, and above all its gateway: the
   router's address in the host's own VLAN. `ip addr` and `ip route` on the host.
2. Is the host's port in the right VLAN? The access VLAN of its switch port, `bridge vlan show`
   on the switch. A correct address on a port in the wrong VLAN is lesson 19's pc5: silence.
3. Does the trunk carry that VLAN, at both ends? The listing of the trunk port on every switch
   on the way and on the router's side. This section's fault lives here.
4. Does the router have an interface in that VLAN, up, with the gateway's address? A
   subinterface or an SVI with the right VLAN number. `ip -br addr` on the router.
5. Is the router forwarding? `ip_forward` on Linux; on a layer 3 switch, routing switched on at
   all.
6. Does a filter refuse it? The rules between the two VLANs, and their counters, which say
   whether a rule has been dropping packets.
7. Does the far side know the way back? The destination's own gateway and port, which is the
   same checklist run from the other end.

Two readings help at every step. The neighbour table on the host tells you whether ARP for the
gateway ever got an answer: `INCOMPLETE` means the question reached nobody who owns the address,
which points at steps 2 to 4. And a capture on the trunk, as in the section on the four crossings,
shows whether a frame crossed and with which tag. Reach first for whichever reading answers the step
you cannot yet rule out; that is what the order is for.
