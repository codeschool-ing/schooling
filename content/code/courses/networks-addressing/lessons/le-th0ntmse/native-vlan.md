---
title: The native VLAN, and the mistakes it hides
version: 1
---

First, the experiment pc5 was set up for. Its address, 10.20.10.25/24, is in pc1's subnet, and
its port on sw2 is in VLAN 20. pc1 pings it, looks at its neighbour table, and pings it once more
while pc5 listens for ARP:

```
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1026ms

ana@pc1:~$ ip neigh
10.20.10.25 dev eth0 INCOMPLETE 
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

root@pc5:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

Nothing gets through, and the neighbour table says why: `INCOMPLETE` means pc1 asked who has
10.20.10.25 and nobody answered. pc5's capture holds `0 packets captured`, so the question never
reached it. pc1's broadcast was put in VLAN 10 at sw1, crossed the trunk tagged as VLAN 10, and
sw2 delivered it to its VLAN 10 port, which is pc3's. **The address says which subnet a machine
believes it is in; the switch port decides which broadcast domain it is actually in, and when the
two disagree the port wins.** A misplaced port looks exactly like this from the PC: a correct
address, a lit link, and silence.

## The one VLAN a trunk carries untagged

A trunk tags its frames, with one exception. The VLAN whose frames cross it without a tag is
called the **native VLAN** (Cisco's word; the standard speaks of the port's PVID). A frame that
arrives on a trunk with no tag is put in the receiving port's native VLAN, so **the two ends of a
trunk have to agree on which VLAN that is**, and nothing in the frame can tell them whether they do.

To see what disagreement does, the lab gives sw1's p24 VLAN 10 as its untagged VLAN, and sw2's p24
VLAN 20:

```
root@sw1:~# bridge vlan add dev p24 vid 10 pvid untagged
root@sw2:~# bridge vlan add dev p24 vid 20 pvid untagged
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10 PVID Egress Untagged
                  20
root@sw2:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10
                  20 PVID Egress Untagged
```

On sw1, VLAN 10 is now `PVID Egress Untagged` on the trunk; on sw2 it is VLAN 20. (VLAN 1 lost its
`PVID` on both and is still listed as leaving untagged, a leftover the fix below does not clean
up either.) Then pc1 pings pc5, which it could not reach in the test above, and pc3, which it could:

```
ana@pc1:~$ ping -c 2 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.934/1.096/1.258/0.162 ms
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1034ms

```

pc1 reaches pc5, in VLAN 20, and loses pc3, in its own VLAN 10. Follow the frame once more. It
enters sw1 in VLAN 10; VLAN 10 is untagged on p24, so it leaves without a tag; sw2 receives an
untagged frame on p24 and puts it in its own untagged VLAN, 20, where pc5 lives. The reply makes
the same journey backwards. **A native VLAN mismatch welds two VLANs together through one cable**,
and the VLAN that should have been on both ends goes dark. The Linux bridge in the lab said nothing
about it. Some switches notice — Cisco's discovery protocol, CDP, reports a native VLAN mismatch to
the log — and a log line is only useful to somebody reading it.

The same property is why the native VLAN appears in every switch hardening guide. **Untagged
traffic on a trunk lands in whatever VLAN the receiving end says**, so a trunk whose native VLAN is
also a VLAN with users in it gives untagged frames a path that no tag decided. The known attacks
on VLAN separation, grouped under the name VLAN hopping, lean on exactly that and on ports that
agree to become trunks when asked. This course does not teach them; it teaches the configuration
that leaves them nothing to work with.

## The fix, and the configuration it should have had

Both ends get the same native VLAN, and it is a number nobody uses, 999. VLANs 10 and 20 go back to
being tagged:

```
root@sw1:~# bridge vlan add dev p24 vid 10 && bridge vlan add dev p24 vid 999 pvid untagged
root@sw2:~# bridge vlan add dev p24 vid 20 && bridge vlan add dev p24 vid 999 pvid untagged
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10
                  20
                  999 PVID Egress Untagged
```

```
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.050/4.222/7.394/3.172 ms
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1035ms

```

pc3 answers again and pc5 is unreachable again, which is the correct result: pc5 is in the wrong
VLAN, and now the network says so. No port in the lab is an access port in VLAN 999, so **an
untagged frame that reaches the trunk now lands in a VLAN where nobody is listening**.

The defences fit in one paragraph, and none costs anything to apply. Make the native VLAN an unused
number, the same at both ends, with no user port in it. List the VLANs each trunk carries and leave
out the rest. Fix every port that faces a user as an access port and switch off automatic trunk
negotiation where the switch has it (Cisco's is called DTP). Keep users out of VLAN 1, which every
switch starts with and every configuration mistake falls back to, and shut down ports with nothing
plugged into them. Where the switch supports it, tag the native VLAN as well, so that nothing on a
trunk travels without a tag at all. The lab's p24 still lists VLAN 1 as untagged; a tidier
configuration would remove it with `bridge vlan del`, which was not run here.
