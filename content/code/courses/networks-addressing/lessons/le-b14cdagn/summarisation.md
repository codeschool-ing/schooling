---
title: "Summarisation: one route for four subnets"
version: 1
---

r2 reaches four subnets through one route, `10.20.32.0/24 via 10.20.32.225`. **Summarising is
announcing one shorter prefix in place of several longer ones it contains**, and it is half the
reason VLSM plans are drawn the way the last two sections drew one. The four subnets fit in one
summary because the plan put them side by side inside one /24. Had operations been given a /27 from
10.20.33.0 instead, r2 would need a second route, or a summary twice the size that also claimed
addresses belonging to somebody else.

The summary is the prefix the subnets have in common. Write the addresses in binary and keep the
bits they all share: 10.20.32.192/27 and 10.20.32.224/27 agree in their first 26 bits, so together
they are 10.20.32.192/26, and the four subnets of this plan agree in their first 24, which is the
/24. **A summary is only as tidy as the plan underneath it**: blocks that are adjacent and aligned
summarise into one line, and blocks scattered across a range need a line each.

What it buys is size and quiet. r2's table is one line for the whole site however many subnets r1
splits it into, and carving a new /28 out of the unused space later changes r1 and nothing upstream.
Across a company with dozens of sites, each announcing one summary, that is the difference between a
table of dozens of lines and a table of thousands, and between a change at one site being news
everywhere or nowhere.

What it costs is that **a summary covers addresses that exist nowhere**. Ask r2 about a real
address and an empty one:

```
root@r2:~# ip route get 10.20.32.140
10.20.32.140 via 10.20.32.225 dev eth0 src 10.20.32.226 uid 0 
    cache 
root@r2:~# ip route get 10.20.32.250
10.20.32.250 via 10.20.32.225 dev eth0 src 10.20.32.226 uid 0 
    cache 
```

The same answer for both: towards r1. 10.20.32.250 is in the plan's unused space, so r1 has no
subnet for it, and r1 does what any router does with an address it has no specific route for: it
uses its default, which points back at r2. A ping from hq1 shows where that ends:

```
ana@hq1:~$ ping -c 1 -W 1 10.20.32.250
PING 10.20.32.250 (10.20.32.250) 56(84) bytes of data.
From 10.20.32.225 icmp_seq=1 Time to live exceeded

--- 10.20.32.250 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

ana@hq1:~$ traceroute -n -m 6 10.20.32.250
traceroute to 10.20.32.250 (10.20.32.250), 6 hops max, 60 byte packets
 1  10.20.99.1  0.846 ms  0.222 ms  0.128 ms
 2  10.20.32.225  0.260 ms  0.177 ms  0.105 ms
 3  10.20.32.226  0.200 ms  0.133 ms  0.311 ms
 4  10.20.32.225  0.158 ms  0.103 ms *
 5  * * *
 6  * * *
```

`Time to live exceeded`, from 10.20.32.225, which is r1. The packet went to r1, back to r2, to r1
again, each router taking one off its TTL, until one of them took the last one and reported it. The
traceroute draws the circle: hop 2 is r1, hop 3 is r2 at 10.20.32.226, hop 4 is r1 again, and after
that the replies stop arriving and the six-hop limit (`-m 6`) ends it. **This is a routing loop**,
and on a busy network it is worse than a lost packet, because every looping packet crosses the same
link again and again until its TTL runs out.

The fix is to make r1 own the whole summary, so that what falls inside it and matches no subnet is
refused at r1 instead of being sent back. One route does it:

```
root@r1:~# ip route add unreachable 10.20.32.0/24
ana@hq1:~$ ping -c 1 -W 1 10.20.32.250
PING 10.20.32.250 (10.20.32.250) 56(84) bytes of data.
From 10.20.32.225 icmp_seq=1 Destination Host Unreachable

--- 10.20.32.250 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 1ms

ana@hq1:~$ ping -c 1 -q 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.725/0.725/0.725/0.000 ms
```

`unreachable 10.20.32.0/24` is a route whose answer is "no". r1's four subnets are longer prefixes
than the /24, so they still win for the addresses they hold (lesson 14 is about that rule), and the
ping to 10.20.32.140 is answered as before. An address in the unused space now matches nothing more
specific than the /24, and r1 answers at once: `Destination Host Unreachable`, one packet, no
circle.

**Whoever announces a summary should hold a route that discards what the summary does not
contain.** Routing protocols that summarise generally install that route for you, pointing at a
discard interface that Cisco calls Null0; with static routes, as here, it is one more line to
remember.
