---
title: Who is allowed to ask
version: 1
---

The marked ping of the last section came from the laptop, and nobody gave the laptop permission. `ana`
typed `-Q 0xb8` as an ordinary user and her ping jumped the queue. **Any program on any machine can
write any DSCP into its own packets**, so a router that believes the mark has handed its priority queue
to whoever asks first. A backup job marked EF would take the voice class and the calls would go back to
waiting.

The fix is a **trust boundary**: the first device the network's owner controls rewrites the mark on
everything that crosses it, and only then puts EF back on what it knows is voice. Here that device is
`hq`, and the rewriting is two `nftables` rules on packets arriving from the office LAN, `eth0`:

```
ana@hq:~$ sudo nft add table ip qos && sudo nft add chain ip qos edge "{ type filter hook prerouting priority mangle; }"
ana@hq:~$ sudo nft add rule ip qos edge iifname eth0 ip dscp set cs0 && sudo nft add rule ip qos edge iifname eth0 ip saddr 192.168.10.10 udp dport 5004 ip dscp set ef
ana@hq:~$ sudo nft list table ip qos
table ip qos {
	chain edge {
		type filter hook prerouting priority mangle; policy accept;
		iifname "eth0" ip dscp set cs0
		iifname "eth0" ip saddr 192.168.10.10 udp dport 5004 ip dscp set ef
	}
}
```

The chain hooks `prerouting` at `priority mangle`, so it runs as a packet arrives, before routing and
long before the classifier on `eth1` reads the byte on the way out. The first rule sets every packet
from the LAN to `cs0`, best effort. The second then marks one kind of traffic EF: UDP to port 5004 from
`files`, `192.168.10.10`, which stands in for the office's voice gateway. **The order is the policy**:
clear everything, then grant the exceptions, the same shape as a firewall that denies by default.

The laptop tries again, with the same upload running:

```
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 24.483/26.292/27.973/1.185 ms
```

**26 ms on average: the laptop's ping is back in the upload's queue.** The laptop still marks its ping EF; `hq` no
longer believes it. And `files` sends one datagram to port 5004, with `echo voice | nc -u -w1
192.0.2.21 5004` typed on `files`, a command with no marking option at all. The ISP sees it arrive:

```
ana@isp:~$ sudo tcpdump -n -v -i eth0 -c 1 udp port 5004
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:13:25.380855 IP (tos 0xb8, ttl 63, id 57798, offset 0, flags [DF], proto UDP (17), length 34)
    203.0.113.2.50848 > 192.0.2.21.5004: UDP, length 6
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

`tos 0xb8`, EF, on a packet whose sender set nothing. `length 6` is the word `voice` and a newline.
**The mark was decided by the network, from the packet's address and port, and not by the program that
sent it**, which is the only kind of mark a router can afford to act on.

Where the boundary goes in a real office is the access switch, the first thing a phone or a laptop is
plugged into. Switches trust the mark on a port where an IP phone sits, often on a voice VLAN of its
own, the idea from `networks-addressing`, and reset it on every other port. A router
further in then has marks it can believe without asking who wrote them.
