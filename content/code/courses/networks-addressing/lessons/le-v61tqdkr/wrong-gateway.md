---
title: A gateway nobody has
version: 2
---

The commonest way to misconfigure a host by hand is to type the gateway wrong. The symptom is easy
to misread, because half the network goes on working. In this block pc2's default route was
replaced, at a root prompt on pc2, with `ip route replace default via 10.20.10.254`: an address
inside the office network that no machine has.

```
ana@pc2:~$ ip route
default via 10.20.10.254 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.22 
ana@pc2:~$ ping -c 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=11.8 ms

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 11.774/11.774/11.774/0.000 ms
```

The route looks fine, and pc2 reaches the server. **Everything on its own network works**, because
that traffic never uses the gateway: the second line of the table sends it straight out of
`eth0`. A user on pc2 can print to the office printer and open the file server, and will report
that "the internet is down".

```
ana@pc2:~$ ping -c 2 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
From 10.20.10.22 icmp_seq=1 Destination Host Unreachable
From 10.20.10.22 icmp_seq=2 Destination Host Unreachable

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1037ms
pipe 2
ana@pc2:~$ ip neigh
10.20.10.254 dev eth0 FAILED 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

Two details in the failure tell you what happened.

**The error comes from pc2's own address**: `From 10.20.10.22 ... Destination Host Unreachable`.
No router said that. pc2's kernel said it, about a host it was trying to reach on its own link,
and the host it was trying to reach was not 192.0.2.80. It was the gateway. To send any packet to
192.0.2.80, pc2 first needs the MAC address of 10.20.10.254, asked for it with ARP, got no answer,
and gave up. (`+2 errors` counts those two reports, and `pipe 2` is ping noting that both probes
were outstanding at once.)

**The neighbour table confirms it**: `10.20.10.254 dev eth0 FAILED`. FAILED is the state of an
address that ARP asked about and nobody answered. The server's line beside it is `REACHABLE`,
which is the difference between the two halves of the symptom.

## Reading the symptom

The pattern is worth keeping because it separates this fault from its neighbours:

| what you see | where the fault is |
|---|---|
| local machines answer, remote ones get "unreachable" from your own address | the gateway is wrong or down; check `ip route` and `ip neigh` |
| local machines answer, and the "unreachable" comes from the gateway's address | the gateway answers but has no route onwards |
| nothing answers, not even local machines | the link or the address, below the gateway |

**The source address of an error message says who gave up.** A message from your own address means
your machine could not hand the packet on; a message from a router means the router could not.
That one habit narrows a vague complaint to a single line of configuration.

The repair here is the address, `10.20.10.1`, in whatever configures pc2: a file, a network
manager, or, on most office networks, the DHCP server that hands every machine its gateway along
with its address, which is lesson 10. A gateway typed wrong on one machine is one user's problem;
the same mistake in a DHCP scope is everybody's, the next time their leases renew.
