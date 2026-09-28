---
title: ARP believes whoever answers
version: 1
---

To send a packet to an address on its own segment, a machine needs that address's **MAC**. ARP asks
the whole segment *who has 192.168.10.1?*, the owner answers *I do, at this MAC*, and the asker keeps
the answer in its **neighbour table** for a while. `laptop`'s table, and the question asked by hand:

```
ana@laptop:~$ ip neigh show dev eth0
192.168.10.1 lladdr 52:54:00:a8:0a:01 REACHABLE 
ana@laptop:~$ arping -c 2 -I eth0 192.168.10.1
ARPING 192.168.10.1 from 192.168.10.20 eth0
Unicast reply from 192.168.10.1 [52:54:00:A8:0A:01]  0.541ms
Unicast reply from 192.168.10.1 [52:54:00:A8:0A:01]  0.550ms
Sent 2 probes (1 broadcast(s))
Received 2 response(s)
```

The gateway, `fw`'s LAN interface, answers from `52:54:00:a8:0a:01`, and that is what `laptop` has
stored.

**ARP has no authentication at all.** Any machine on the segment can answer a question, or announce an
answer nobody asked for, and the others will generally believe it and update their tables. That is
the whole of **ARP spoofing**, also called ARP poisoning: a machine on the segment tells the others
that the gateway's address is at *its* MAC. From then on, their traffic for the outside world goes to
it first. If it passes the traffic on, nothing visibly breaks, and it reads everything the previous
section showed is readable.

Three consequences for a defender:

- **An attacker needs to be on the segment.** ARP does not cross a router, so spoofing is a threat from
  a machine already inside the LAN: a compromised laptop, or something plugged into a free socket.
  Lesson 22 is about who may plug in at all.
- **The symptom is one address with two MACs**, or one address whose MAC changes. That can be seen,
  and the next section sees it.
- **Encryption defeats the purpose.** Traffic that passes through the wrong machine over TLS, with the
  certificate checked, yields nothing to it but metadata. That is the thread lesson 13 picks up.
