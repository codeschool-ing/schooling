---
title: Virtual IPs and DNS
version: 1
---

The two approaches this lab cannot show honestly, because both are about more than one machine.

A **virtual IP** is an address that does not belong to any one server: whichever machine is the
primary adds it to its own network interface and announces it on the network, and the application
connects to that address. On a failover the new primary takes the address over. Tools such as
`keepalived`, or `vip-manager`, which reads Patroni's leader key from etcd, do the moving. It is fast,
and it works only where the network lets an address move between machines, which most clouds do
not: there, a **load balancer** provided by the cloud plays the same role, and is a proxy by another
name.

**DNS** puts the primary behind a name, and a failover changes the record. It needs no special network,
and it is slow to take effect in ways nobody controls: every resolver along the way, and often the
application's own runtime, caches the old answer for the record's **TTL** at least, and some for longer.
A TTL of a few seconds helps and costs a lookup on every connection. DNS suits a planned switchover
announced in advance better than a failover at three in the morning.

Whichever of the four a system uses, test it the way the last section did: switch, and **watch what an
application actually experiences**, not what the cluster manager reports.
