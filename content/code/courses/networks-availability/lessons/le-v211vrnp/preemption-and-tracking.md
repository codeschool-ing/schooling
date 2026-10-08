---
title: Taking the address back, and giving it away
version: 1
---

When `hq`'s cable goes back in, `sudo ip -n wire link set hq-hq up` on the virtual machine, `hq2` is
master and everything works. Whether `hq` should now take the
address back is a choice, called **preemption**, and VRRP's default is yes: a router with a higher
priority that comes back takes over again. keepalived follows the default, and the laptop caught what
`hq` sends when it does, with the capture started before the cable went back. The filter keeps only ARP
from `hq`'s hardware address:

```
ana@laptop:~$ sudo tcpdump -n -t -e -i eth0 -c 2 arp and ether src 52:54:00:a8:0a:02
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
52:54:00:a8:0a:02 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.1 (ff:ff:ff:ff:ff:ff) tell 192.168.10.1, length 28
52:54:00:a8:0a:02 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.1 (ff:ff:ff:ff:ff:ff) tell 192.168.10.1, length 28
2 packets captured
5 packets received by filter
0 packets dropped by kernel
ana@hq:~$ grep -E "Entering" /run/keepalived.log
Mon Sep 28 18:10:55 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:59 2026: (office) Entering MASTER STATE
Mon Sep 28 18:11:06 2026: (office) Entering FAULT STATE
Mon Sep 28 18:11:12 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:16 2026: (office) Entering MASTER STATE
ana@laptop:~$ ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:02 STALE 
```

`hq`'s log has the whole story of its afternoon. Master at 18:10:59; `FAULT` at 18:11:06, when the cable
came out; back to `BACKUP` at 18:11:12, when it returned; master again at 18:11:16. It did not take over
the second its cable was back. It came back as a backup, listened, and became master four seconds later
by the log's whole-second clock, the same kind of wait as at start-up.

## Gratuitous ARP

The two packets it sent the moment it took over are strange ones. They are ARP requests, broadcast to
`ff:ff:ff:ff:ff:ff`, asking `who-has 192.168.10.1` and signed `tell 192.168.10.1`: **a router asking the
whole LAN who has its own address**. Nobody is meant to answer. The point is the sender's hardware
address inside the request, `52:54:00:a8:0a:02`. Every host that already has an ARP entry for
`192.168.10.1` updates it to the sender's MAC, and the laptop's entry is back to `hq`'s `:02` without the
laptop having asked. This is a **gratuitous ARP**, and it is how the new master of a failover repoints
every host in one broadcast instead of waiting for their caches to expire. `STALE` only means the entry
has not been confirmed recently.

## The cost of taking it back

Preemption means **the office goes through a second switch-over when the failed router returns.** It is a short one, since `hq` announces itself at once instead of waiting for a silence. No ping was running during this return, so it was not measured. It makes sense when `hq` is the better router, with a faster
link or a bigger box. When the two are equal it buys an interruption and nothing else. keepalived's `nopreempt` turns it off, or `preempt_delay` makes a returning router wait, so that one that keeps
flapping does not drag the gateway with it.

## Tracking: giving the address away on purpose

A router can be alive on the LAN and useless. If `hq` loses its link to the ISP, it still answers VRRP
on `eth0`, still wins the election with priority 150, and every host keeps sending it traffic it has
nowhere to send. **A gateway with no way out is worse than a dead one**, because a dead one would at least
have been replaced.

That is what `track_interface` in the configuration is for: `eth1` is `hq`'s link to the ISP, and if it
goes down, keepalived puts the instance into `FAULT` and gives up the address. The ISP link was taken
down while `hq` was master, the same way as the LAN cable: `sudo ip -n wire link set hqwan-hq down` on
the virtual machine, and five seconds' wait:

```
ana@hq:~$ grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:16 2026: (office) Entering MASTER STATE
Mon Sep 28 18:11:16 2026: Netlink reports eth1 down
Mon Sep 28 18:11:16 2026: (office) Entering FAULT STATE
ana@hq2:~$ ip -br addr show eth0
eth0@if1240      UP             192.168.10.3/24 192.168.10.1/24 
ana@laptop:~$ ping -c 2 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.214 ms
64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.118 ms

--- 192.0.2.21 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1006ms
rtt min/avg/max/mdev = 0.118/0.166/0.214/0.048 ms
```

In the same second by the log's clock that `hq` became master again, it reported `eth1` down and went to
`FAULT`. **`hq2` holds `192.168.10.1` again, and the laptop's ping goes through it with no loss**, even
though `hq` is running and its LAN cable is fine. When the ISP link came back, `sudo ip -n wire link set hqwan-hq up`, `hq` went through the same steps as
before:

```
ana@hq:~$ grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:22 2026: Netlink reports eth1 up
Mon Sep 28 18:11:22 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:26 2026: (office) Entering MASTER STATE
```

`hq`'s link came up at 18:11:22, it rejoined as a backup, and took the address back at 18:11:26.

Cisco's routers track differently, and it trips people up: a tracked interface there usually **lowers
the priority** by a set amount instead of leaving the election. The partner then takes over only if it is
allowed to preempt, so a rule that lowers `hq` to 90 does nothing while `hq2` has preemption off.
