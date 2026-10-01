---
title: A mark is a request, not a service
version: 1
---

The first step, recognising what matters, is easiest if the packet says so itself. Every IPv4 header
carries one byte for it, the second one, which `tcpdump` still calls `tos`, type of service. **Its top
six bits are the DSCP, Differentiated Services Code Point, and they name a class**; the bottom two
belong to congestion notification (ECN) and are left alone here.

A few values are agreed across the industry, which is the point of having a code at all:

| name | DSCP | the whole byte | meant for |
|---|---|---|---|
| EF, expedited forwarding | 46 | `0xb8` | voice |
| AF41 | 34 | `0x88` | interactive video |
| CS6 | 48 | `0xc0` | routing protocols |
| CS0, default | 0 | `0x00` | everything else, best effort |

The third column is the one tools print, because they show the whole byte. Moving six bits two places
to the left multiplies by four: **46 × 4 = 184, which is `0xb8`**. `ping -Q` takes the whole byte too,
so a ping that asks to be treated as voice is `ping -Q 0xb8`. Here is one, captured on the ISP's side
of `hq`'s uplink:

```
ana@isp:~$ sudo tcpdump -n -v -i eth0 -c 2 icmp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:13:11.065092 IP (tos 0xb8, ttl 63, id 8227, offset 0, flags [DF], proto ICMP (1), length 84)
    203.0.113.2 > 192.0.2.21: ICMP echo request, id 45272, seq 1, length 64
18:13:11.065115 IP (tos 0xb8, ttl 63, id 10711, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.21 > 203.0.113.2: ICMP echo reply, id 45272, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

`tos 0xb8` on the request, so the mark crossed `hq` intact, and NAT, which rewrote the source to
`203.0.113.2`, did not touch it. The reply carries `0xb8` as well, because Linux copies the byte of an
echo request into its reply. **Nothing on the path did anything with it.** The ISP's router read the
byte, printed it and forwarded the packet exactly as it forwards every other.

## A mark with no queue behind it

What does the mark buy on the congested uplink of the last section, where there is still one queue for
everything? This ping ran during the same upload, a few seconds after the unmarked one:

```
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.055/20.045/26.474/10.067 ms
```

The worst reply took 26 ms, which is the same queue as before. One reply of the five came back in
0.055 ms, so it found the queue empty for an instant, and the upload had filled it again by the next.
The averages, 20 ms marked against 65 ms unmarked, look like a difference and are not one. The unmarked
run started two seconds into the upload and caught one reply at 221 ms, at a moment when the queue was
nearly full. An average times five is the sum, so the other four unmarked replies averaged (5 × 65.122 −
221.652) ÷ 4, about **26 ms**, and the four slow marked ones (5 × 20.045 − 0.055) ÷ 4, about **25 ms**.

**A mark is a label, and a label does nothing until something is configured to read it.** A router
with one queue sends packets in the order they arrived, whatever they say about themselves. The mark is
a request, and the next section builds the queue that grants it.
