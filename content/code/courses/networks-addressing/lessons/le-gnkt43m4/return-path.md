---
title: Every route needs its way back
version: 1
---

**A route points one way.** r1's line for `10.20.3.0/24` says how to get there and nothing about how to
come back, and a ping is two journeys. The reply from pc3 starts on r3, so r3 needs a route to pc1's
network, and r2, which the reply crosses next, needs one too:

```
root@r3:~# ip route add 10.20.1.0/24 via 10.20.23.1
root@r2:~# ip route add 10.20.1.0/24 via 10.20.12.1
```

Now the ping:

```
ana@pc1:~$ ping -c 2 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
64 bytes from 10.20.3.10: icmp_seq=1 ttl=61 time=1.39 ms
64 bytes from 10.20.3.10: icmp_seq=2 ttl=61 time=1.31 ms

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.311/1.352/1.394/0.041 ms
```

Two replies, no loss. `ttl=61` counts the routers on the way back: pc3 sent the reply with a TTL of 64,
and r3, r2 and r1 each took one off. The `1.39 ms` is this lab, three namespaces on one virtual machine,
and says nothing about real networks.

`traceroute` names every router going out:

```
ana@pc1:~$ traceroute -n 10.20.3.10
traceroute to 10.20.3.10 (10.20.3.10), 30 hops max, 60 byte packets
 1  10.20.1.1  2.280 ms  0.278 ms  0.197 ms
 2  10.20.12.2  0.256 ms  0.240 ms  0.305 ms
 3  10.20.23.2  0.341 ms  0.190 ms  0.125 ms
 4  10.20.3.10  0.840 ms  0.212 ms  0.107 ms
```

Four hops: r1's address on pc1's network, r2's end of the first `/30`, r3's end of the second, and pc3.
There is a detail here worth a second look. **r1 still has no route to `10.20.23.0/30`**, the cable
between r2 and r3, and hop 3 printed `10.20.23.2` anyway. That works because r3's answer to traceroute
was addressed to `10.20.1.10`, and every router on the way back has a route for pc1's network. A route
is needed for the destination of each packet, not for every address that appears in the conversation.

r2 is in the middle, so its table shows both halves of the work:

```
root@r2:~# ip route
10.20.1.0/24 via 10.20.12.1 dev eth1 
10.20.3.0/24 via 10.20.23.2 dev eth2 
10.20.12.0/30 dev eth1 proto kernel scope link src 10.20.12.2 
10.20.23.0/30 dev eth2 proto kernel scope link src 10.20.23.1 
```

Two typed routes, one for each direction, and its two connected `/30`s. **Static lines carry no `proto
kernel`**: they are not derived from an address on an interface, they were added. That difference is
how you tell, on a router you did not configure, which lines a person is responsible for.

## Counting the routes

The two PC networks needed four routes: r1 and r2 towards `10.20.3.0/24`, r3 and r2 towards
`10.20.1.0/24`. **Every router on the path needs a route for every network it is not connected to and
has to forward to.** Add a third network behind r2 and r1 and r3 each need one more line, and anything
that should reach it from the other networks needs its way back too.

Two habits follow:

- **Write both directions in the same change.** A change request that adds a route towards a network
  and not the return is half a change, and the half that is missing fails silently, as the previous
  section showed.
- **Test from both ends.** A ping from pc1 tests both directions at once and tells you nothing about
  which one broke. A `traceroute` from each side, or a capture at the far end, does.

The forward and return paths do not have to be the same. On this chain they are, because there is only
one way through r2. The next section adds a second way, and from then on the two directions can split,
which is where static routing gets into trouble.
