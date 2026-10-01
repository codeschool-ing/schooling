---
title: A wrong mask, and what it breaks
version: 1
---

A mask is not only arithmetic on paper. **Every time a machine sends a packet, it uses its own mask to
decide one thing.** Is the destination on my link, so I ask for its MAC address and send it directly?
Or is it somewhere else, so I hand the packet to the gateway? A wrong mask makes that decision wrong
for some destinations and right for others, which is why the failure it causes is so confusing.

sales1 as it was built, with its `/25`:

```
ana@sales1:~$ ip route
default via 10.20.32.1 dev eth0 
10.20.32.0/25 dev eth0 proto kernel scope link src 10.20.32.10 
ana@sales1:~$ ip route get 10.20.32.100
10.20.32.100 dev eth0 src 10.20.32.10 uid 1000 
    cache 
ana@sales1:~$ ip route get 10.20.32.140
10.20.32.140 via 10.20.32.1 dev eth0 src 10.20.32.10 uid 1000 
    cache 
```

Two routes. `10.20.32.0/25 dev eth0` is the **connected route**, which Linux adds by itself from the
address and mask: everything in `.0` to `.127` is on `eth0`, reached directly. `default via
10.20.32.1` is everything else. `ip route get` shows the decision for two destinations. `.100` is
inside the `/25`, so the answer is `dev eth0` with no `via`: sales1 would ask for `.100`'s MAC itself,
though no machine in this lab has that address. `.140` is outside, so the answer is `via 10.20.32.1`:
the packet goes to r1, which knows eng1 is on its `eth2`.

Now the mistake, typed by hand: the address set again with `/24`, the size of the whole block, the
way somebody might when they remember "the office is 10.20.32.0/24" and not the plan.

```
root@sales1:~# ip addr del 10.20.32.10/25 dev eth0 && ip addr add 10.20.32.10/24 dev eth0 && ip route add default via 10.20.32.1
ana@sales1:~$ ip route
default via 10.20.32.1 dev eth0 
10.20.32.0/24 dev eth0 proto kernel scope link src 10.20.32.10 
ana@sales1:~$ ping -c 2 -W 1 10.20.99.10
PING 10.20.99.10 (10.20.99.10) 56(84) bytes of data.
64 bytes from 10.20.99.10: icmp_seq=1 ttl=62 time=11.4 ms
64 bytes from 10.20.99.10: icmp_seq=2 ttl=62 time=0.877 ms

--- 10.20.99.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.877/6.117/11.358/5.240 ms
ana@sales1:~$ ping -c 2 -W 1 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1056ms

```

The connected route is now `10.20.32.0/24`. A ping to hq1, `10.20.99.10`, behind r2, works perfectly,
`ttl=62` because it crossed two routers. A ping to eng1, `10.20.32.140`, two cables away, loses both
packets. **The far machine works and the near one does not**, which is the opposite of what anybody
expects from a network fault. The neighbour table says why:

```
ana@sales1:~$ ip neigh
10.20.32.1 dev eth0 lladdr 02:a6:80:20:13:54 REACHABLE 
10.20.32.140 dev eth0 INCOMPLETE 
ana@sales1:~$ ip route get 10.20.32.140
10.20.32.140 dev eth0 src 10.20.32.10 uid 1000 
    cache 
```

`10.20.32.140 dev eth0 INCOMPLETE`. sales1 believed eng1 was on its own link, because `.140` is inside
the `/24` it now has, so it sent ARP requests for `.140` out of `eth0` and waited for an answer. eng1 is
on a different cable, behind r1, and never heard them. r1 heard them on `eth1` and did not answer
either, because `.140` is not one of its addresses. `ip route get` confirms it: `dev eth0`, no `via`.
The packet never went to the gateway at all.

**The symptom of a mask that is too short is a set of addresses that fail together and an
`INCOMPLETE` entry for each one tried.** Here the set is `.128` to `.255`, eng1's LAN and ops1's, because
those are the addresses the wrong `/24` added to sales1's idea of its own link. The internet, the head
office and the gateway itself all keep working, so the user's report will be "some servers are down",
and the servers are fine.

The opposite mistake, a mask that is too long, was not run in this lab. It makes a machine send
packets for its real neighbours to the gateway; whether they then arrive depends on what the router
does with a packet that has to go back out of the interface it came in on.

Diagnosing either takes two commands, both seen in this lesson. **Compare the address and prefix in
`ip -br addr` with the plan, and ask `ip route get` about the address that fails.** A destination that
should be remote answering `dev eth0` with no `via` is a mask that is too short, and an `INCOMPLETE`
line in `ip neigh` is the same fact seen from the other side.
