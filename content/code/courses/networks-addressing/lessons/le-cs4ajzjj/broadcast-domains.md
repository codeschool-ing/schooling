---
title: "Broadcast domains: how far a question reaches"
version: 1
---

Some frames are for everybody. ARP's question, *who has 10.20.10.22?*, has to reach a machine whose
MAC address the sender does not know yet, so it goes to the broadcast address,
`ff:ff:ff:ff:ff:ff`, and every switch floods it. **A broadcast domain is the set of devices a
broadcast reaches**, and the useful thing to know about it is where it ends.

A common belief is that a switch keeps broadcasts apart, since it keeps everything else apart. It
does not: a switch splits collision domains, and passes broadcasts out of every port, because a
broadcast asks to be delivered everywhere. In this block pc1, with its neighbour table emptied,
pings pc2, while pc3 listens for ARP. tcpdump on pc3 was started first and printed when it stopped:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 3.034/3.034/3.034/0.000 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:58:31.168784 02:25:70:bc:29:c6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.10.22 tell 10.20.10.21, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

pc3 caught **one frame, from pc1's MAC to `ff:ff:ff:ff:ff:ff`: `Request who-has 10.20.10.22 tell
10.20.10.21`**. It is not pc3's question to answer and pc3 did not answer it, but its card received
it and its system had to look at it. Every machine on sw1, the router's office interface included,
received the same frame.

The second half of the block listens on the far side of the router. The provider's machine, isp,
sits on r1's other interface. pc1's neighbour table is emptied again and the same ping repeated,
so the same broadcast question goes out again:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.244/1.244/1.244/0.000 ms
root@isp:~# timeout 6 tcpdump -n -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

**isp captured nothing.** The question reached r1's office interface, as it reached everybody on
sw1, and stopped there. **A router does not forward broadcasts**: it forwards packets addressed to
another network, and a frame to everybody on this link is addressed to no other network at all. So
every interface of a router is the edge of a broadcast domain, and the office's ARP traffic never
reaches the provider.

## Counting them

Put lessons 1 and 2 and this one side by side:

| device | collision domains | broadcast domains |
|---|---|---|
| hub or repeater | one, shared by every port | one |
| bridge or switch | one per port | one, shared by every port |
| router | one per interface | one per interface |

In this lab, sw1's five ports are five collision domains and one broadcast domain, 10.20.10.0/24;
the link from r1 to the provider is another broadcast domain; and so on, one per network.

## Why the size matters

**Every broadcast is received and examined by every machine in the domain.** Ten machines asking
ARP questions are background noise. A few thousand on one flat network are a steady load on every
one of them, and one misbehaving device sending broadcasts in a loop is felt everywhere at once.
The worst case is a cable that joins two ports of the same switched network: a broadcast goes round
the loop for ever, every switch floods every copy, and the network stops. That is a **broadcast
storm**, and preventing it is lesson 20.

So networks are cut into broadcast domains on purpose, one per department, floor or purpose, with a
router between them. Doing that with a separate switch for each domain is expensive and rigid;
**lesson 19 cuts one switch into several broadcast domains** with VLANs, and lesson 22 puts the
router back between them.
