---
title: Finding a neighbour without ARP or broadcast
version: 1
---

IPv6 has no broadcast address at all, and no ARP. The job ARP did, turning an IP address into a MAC
address on the same link, is done by **Neighbour Discovery**, a set of ICMPv6 messages that also
includes the router advertisements of the previous section. What changes is who gets interrupted
by the question.

Both neighbour tables were emptied before this capture, so pc1 has to ask. pc1 pings srv, and
meanwhile `tcpdump` on srv was printing what arrived; its output came out after the ping finished:

```
ana@pc1:~$ ping -c 1 2001:db8:20:10::10
PING 2001:db8:20:10::10 (2001:db8:20:10::10) 56 data bytes
64 bytes from 2001:db8:20:10::10: icmp_seq=1 ttl=64 time=3.03 ms

--- 2001:db8:20:10::10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 3.029/3.029/3.029/0.000 ms
root@srv:~# timeout 6 tcpdump -n -c 4 -i eth0 icmp6
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:48:29.074885 IP6 2001:db8:20:10:25:70ff:febc:29c6 > ff02::1:ff00:10: ICMP6, neighbor solicitation, who has 2001:db8:20:10::10, length 32
07:48:29.076700 IP6 2001:db8:20:10::10 > 2001:db8:20:10:25:70ff:febc:29c6: ICMP6, neighbor advertisement, tgt is 2001:db8:20:10::10, length 32
07:48:29.077017 IP6 2001:db8:20:10:25:70ff:febc:29c6 > 2001:db8:20:10::10: ICMP6, echo request, id 10, seq 1, length 64
07:48:29.077113 IP6 2001:db8:20:10::10 > 2001:db8:20:10:25:70ff:febc:29c6: ICMP6, echo reply, id 10, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four packets, in the same order as the networks course showed for ARP. First a **neighbour
solicitation**, *who has 2001:db8:20:10::10*, from pc1's global address. Then srv's **neighbour
advertisement**, *tgt is 2001:db8:20:10::10*, sent straight back to pc1. Then the ping itself. The
advertisement left srv 1.815 milliseconds after the solicitation reached it, which is this lab's
virtual machine and not a property of the protocol.

The interesting part is the destination of the question. ARP sent its question to
`ff:ff:ff:ff:ff:ff`, and every machine on the link had to read it. **The solicitation went to
`ff02::1:ff00:10`, a solicited-node multicast address**: `ff02::1:ff` followed by the last 24 bits of
the address being looked for. srv's address ends in `00:00:10` (the last two groups, `0000:0010`, with
their last six hex digits taken), so the group is `ff02::1:ff00:10`. Every machine joins the group
for each of its own addresses, so in practice only the machine with the right address, and the rare
one whose address happens to end in the same 24 bits, has to look at the question. pc2, whose
addresses end in `d2:63ba`, is in group `ff02::1:ffd2:63ba` and never had to read this one.

The answer lands in the same kind of table ARP fills:

```
ana@pc1:~$ ip -6 neigh
2001:db8:20:10::10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

`02:9e:43:3e:ca:ae` is srv's MAC, and you can check it against srv's link-local address from the first
section of this lesson, `fe80::9e:43ff:fe3e:caae`: the same digits with `ff:fe` in the middle and the
`02` turned into `00`.

There is still a way to reach every machine on a link, and it is a multicast group too:
**`ff02::1`, all nodes**. Every IPv6 interface joins it. `ff02::` addresses are link-scoped, as `fe80::`
addresses are, so the ping needs a zone:

```
ana@pc1:~$ ping -w 2 ff02::1%eth0
PING ff02::1%eth0 (ff02::1%eth0) 56 data bytes
64 bytes from fe80::25:70ff:febc:29c6%eth0: icmp_seq=1 ttl=64 time=0.716 ms
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=1 ttl=64 time=2.08 ms
64 bytes from fe80::6a:dcff:fe93:3b8a%eth0: icmp_seq=1 ttl=64 time=2.37 ms
64 bytes from fe80::9e:43ff:fe3e:caae%eth0: icmp_seq=1 ttl=64 time=2.63 ms
64 bytes from fe80::fd:f2ff:fed2:63ba%eth0: icmp_seq=1 ttl=64 time=2.64 ms
64 bytes from fe80::25:70ff:febc:29c6%eth0: icmp_seq=2 ttl=64 time=0.763 ms
64 bytes from fe80::6a:dcff:fe93:3b8a%eth0: icmp_seq=2 ttl=64 time=1.23 ms
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=2 ttl=64 time=1.38 ms
64 bytes from fe80::9e:43ff:fe3e:caae%eth0: icmp_seq=2 ttl=64 time=1.39 ms
64 bytes from fe80::fd:f2ff:fed2:63ba%eth0: icmp_seq=2 ttl=64 time=1.39 ms

--- ff02::1%eth0 ping statistics ---
2 packets transmitted, 2 received, +8 duplicates, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.716/1.657/2.635/0.683 ms
```

Each request drew five answers, so two requests made `2 received, +8 duplicates`. The five are, by
their link-local addresses: `fe80::25:70ff:febc:29c6`, pc1 itself, which is a member of the group like
everybody else; `fe80::1f:23ff:fee7:e9d5`, r1; `fe80::9e:43ff:fe3e:caae`, srv;
`fe80::fd:f2ff:fed2:63ba`, pc2; and `fe80::6a:dcff:fe93:3b8a`, the switch. In this lab sw1 is a Linux
bridge, and the bridge has an interface of its own with a link-local address like any other; an
unmanaged switch with no address would not have answered.

**A ping to `ff02::1` is the quickest census of an IPv6 link**, and unlike the broadcast ping of lesson
8 nobody had to change a setting for it: Linux answers echo requests to all-nodes by default. No router forwards a
`ff02::` packet off its link, so this census only ever sees the cable it was sent on.
