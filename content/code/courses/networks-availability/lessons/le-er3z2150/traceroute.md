---
title: traceroute, and the hop that says nothing
version: 1
---

traceroute sends probes with a TTL of 1, then 2, then 3. Each router that takes a probe's TTL to zero
discards it and answers with an ICMP "time exceeded", and those answers, hop by hop, are the path. **What
the probe is made of is a choice**, and the three choices on Linux behave differently:

```
ana@laptop:~$ traceroute -n 192.0.2.22
traceroute to 192.0.2.22 (192.0.2.22), 30 hops max, 60 byte packets
 1  192.168.10.1  0.076 ms  0.026 ms  0.025 ms
 2  203.0.113.1  0.380 ms  0.226 ms  0.193 ms
 3  192.0.2.22  0.370 ms  0.238 ms  0.212 ms
ana@laptop:~$ traceroute -n -I 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  0.077 ms *  0.004 ms
 2  * 203.0.113.1  0.168 ms *
 3  192.0.2.21  0.016 ms  0.007 ms  0.007 ms
ana@laptop:~$ sudo traceroute -n -T -p 80 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  5.105 ms * *
 2  203.0.113.1  5.031 ms  5.043 ms *
 3  192.0.2.21  0.338 ms  0.245 ms  0.299 ms
```

The default sends UDP to high ports. The destination has nothing listening on them, answers "port
unreachable", and that is how traceroute knows it has arrived. `-I` sends ICMP echoes, like ping. `-T -p
80` sends TCP SYNs to port 80, which gets through firewalls that pass web traffic and drop everything
else; it builds its packets on a raw socket, which is why it ran with `sudo`. **Pick the probe that the
traffic you care about looks like**, because a firewall that drops UDP to high ports can make a healthy
path look broken.

All three runs found the same three hops: `hq` at `192.168.10.1`, the ISP at `203.0.113.1` and the
server. **The stars in the second and third runs are not a fault**, and nothing was staged for them.
Routers limit how fast they send ICMP errors, traceroute fires its probes in quick bursts, and some
answers are simply not sent. The next section measures that limit. The times need the same care. The
TCP probes' first two hops took about 5 ms while the server answered in 0.338. **A hop's time is how
long that router took to answer.** A router writes error messages at low priority, so a slow middle
hop followed by a fast destination measures the router's attention, not the path.

## A silent hop

For the next run the ISP router was told to drop every "time exceeded" it sends, and traceroute asked
for one probe per hop with `-q 1`:

```
ana@laptop:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  0.068 ms
 2  *
 3  192.0.2.21  0.209 ms
```

Hop 2 is a star, and hop 3, the server, answers in 0.209 ms. **A silent hop is not a broken hop.** Every
probe that reached the server went through the ISP router, so forwarding works; what is missing is only
the router's own answer. Carriers configure routers like this on purpose, to hide their internal
addresses or to spare the processor. **What does mean trouble is a trace that goes silent and stays
silent to the end**: then the probes are not getting further, and the last hop that answered is where to
start asking.
