---
title: "The hub: every frame out of every port"
version: 2
---

A hub is often described as a slow switch. It is a different kind of device. **A hub has no table
and reads no address: whatever signal arrives on one port, it repeats on every other port, bit by
bit.** It works at layer 1, the same layer as a cable, and from the point of view of the machines
plugged into it, it is one long cable with several ends.

That has two consequences the switch section did not have. Every machine receives every frame,
including the ones addressed to somebody else; its network card checks the destination MAC and
throws away what is not its own, but the frame was on its cable. And because all the ports share
one signal, **only one machine can transmit at a time**: two that start together garble each
other's frames, which is a collision. Lesson 18 shows how Ethernet copes with that and why a switch
removed the problem.

## Making the lab's switch behave like one

A hub is hard to buy today, and a namespace has no electrical signal to repeat, so this lab cannot
run a real one. It can imitate what a hub does to traffic. The switch forgets each learnt address
after an **ageing time**; set that to zero and it forgets every address the moment it learns it.
With an empty table, every frame is sent out of every port, which is the behaviour of a hub. At a
root prompt on sw1, `ip link set br0 type bridge ageing_time 0` makes the change, and
`ageing_time 30000`, the default of 300 seconds counted in hundredths, undoes it afterwards:

```
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 0
ana@pc1:~$ ping -c 3 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=2.89 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=0.943 ms
64 bytes from 10.20.10.22: icmp_seq=3 ttl=64 time=0.961 ms

--- 10.20.10.22 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 0.943/1.597/2.888/0.912 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:09:07.939704 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 1, length 64
15:09:07.941625 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 1, length 64
15:09:08.941412 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 2, length 64
15:09:08.941667 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 2, length 64
15:09:09.943482 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 3, length 64
15:09:09.943991 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 3, length 64

6 packets captured
6 packets received by filter
0 packets dropped by kernel
```

`ageing_time 0` is the change. Then pc1 pings pc2 three times, exactly as in the switch section,
while pc3 listens. tcpdump on pc3 was started first and printed when it stopped, so its output is
last. This time it caught **6 packets**: three echo requests from `02:25:70:bc:29:c6` (pc1) to
`02:fd:f2:d2:63:ba` (pc2), and three replies the other way. Not one of them was addressed to pc3.

pc3 only shows them because tcpdump asks the card to keep every frame instead of discarding the
ones for other machines, which is called promiscuous mode. **On a hub, any machine that asks can read
every conversation on it**, which is one of the reasons hubs were replaced. A switch does not stop
somebody determined, and lesson 18 shows how a switch is kept from flooding; but it does stop the
ordinary case, where the frames never reach the third machine at all.

## Where the imitation stops

The imitation shows the result and not the mechanism, and the difference is worth one paragraph.
The lab's bridge still receives each frame whole, still decides in software to flood it, and still
sends on each cable in both directions at once. A real hub decides nothing: it copies the electrical
signal as it arrives, before the end of the frame exists, so a collision on one port is a collision
on all of them. **A hub is one collision domain; a switch has one per port**, and lesson 18 draws the
difference.

You will still meet hubs in three places: old installations nobody has replaced, exam questions
about collision domains, and the behaviour of a switch whose table is empty or full, which floods
exactly like the capture above.
