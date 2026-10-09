---
title: The star, and the two ways it breaks
version: 2
---

In a **star**, every device has its own cable to one central device — today a switch. It is the
shape of almost every office, and of lesson 1's office, built with
`sudo bash ~/netlab/netlab.sh up office`: pc1, pc2, pc3, the server
`srv` at `10.20.10.10` and the router r1 each have one cable to the switch sw1, and nothing else
joins them.

A star has exactly two kinds of failure: an arm, or the centre. They look completely different
from a desk, and that difference is most of what the star has to teach.

## One cable

The first experiment unplugs pc3. On the switch, its port `p3` is set down, which is what the
switch sees when a cable is pulled. Then pc3 tries the server, and so does pc1:

```
root@sw1:~# ip link set p3 down
ana@pc3:~$ ping -c 2 -W 1 10.20.10.10
ping: connect: Network is unreachable
ana@pc1:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=6.09 ms
64 bytes from 10.20.10.10: icmp_seq=2 ttl=64 time=1.02 ms

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.018/3.555/6.092/2.537 ms
```

pc3 does not even send a packet. **`Network is unreachable` is the machine refusing on its own**:
its card has lost the signal, the route to `10.20.10.0/24` belonged to that card, and with the
card down pc3 has no route to anywhere. The networks course read the same message as a failure of
the link on the machine itself.

pc1, two ports away on the same switch, does not notice. Its two pings come back. **A broken arm
of a star is one machine's problem**, and the machine says so loudly. The first reply took 6.09 ms
and the second 1.02 ms: the first also waited for pc1 to ask the server's MAC address with ARP, and
both are times of this lab's virtual machine, not a property of switches.

## The centre

The second experiment leaves every cable alone and switches off the switch's bridge, `br0` — the
part that forwards frames between ports. Now pc1 and pc2 both try the server:

```
root@sw1:~# ip link set br0 down
ana@pc1:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1054ms

ana@pc2:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1047ms

```

**Everybody loses, and nobody gets an error.** Both machines' cables are fine, their cards still
have a signal, their routes are intact, so each one sends its request and waits. Nothing comes back:
`2 packets transmitted, 0 received, 100% packet loss`. pc3 and the server would have printed the
same thing.

That silence is the star's real cost. **The centre is a single point of failure for every machine
on it**, and when it fails, every machine reports the same symptom, which is no symptom at all. The
diagnosis comes from noticing that *everyone* lost the network at once — the first question on the
phone is "is it only you?" — and from the lights on the switch, which on a real one go dark on
every port together.

## Why the star won anyway

Against the bus and the shared ring of the previous section, the star's trade is a good one:

- **A broken cable takes down one machine, not the segment.** Adding or moving a machine is one
  new cable and disturbs nobody.
- **A fault is easy to find.** Each port has its own light and its own counters on the switch, so
  "which cable?" has an answer without walking the building.
- **The centre can be clever.** A switch sends each frame only to the port where its destination
  lives, so the cables stop being shared (lesson 18).

The price is more cable, since every machine runs all the way to the cupboard — twisted-pair
Ethernet allows 100 metres per run — and a centre that has to be trusted. Lesson 6 returns to that
centre with the vocabulary for it: a single point of failure, and the ways a design removes one.
