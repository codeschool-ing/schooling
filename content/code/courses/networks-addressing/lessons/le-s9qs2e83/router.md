---
title: "The router: between networks"
version: 1
---

A switch joins machines of one network. **A router joins networks: it has an address on each of
them, reads the destination IP address of every packet, and sends the packet on towards the
network that address belongs to.** The frame around the packet is thrown away at the router and a
new one is built for the next link, which lesson 2 shows byte by byte.

The lab's router is r1. It has two interfaces, one in the office and one towards the provider:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if31        UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if33        UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
root@r1:~# ip route
default via 203.0.113.1 dev eth1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
203.0.113.0/30 dev eth1 proto kernel scope link src 203.0.113.2 
root@r1:~# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
```

`ip -br addr` gives r1 two addresses on two different networks: `10.20.10.1/24` on `eth0`, the
office, and `203.0.113.2/30` on `eth1`, the link to the provider. (The `fe80::` addresses are IPv6
link-local ones, which every interface gets on its own; lesson 9 is about them.) `ip route` is its
**routing table**, three lines long: the two networks it is cabled to, and `default via
203.0.113.1`, which says that a packet for any other network goes to the provider. Lesson 14 reads
tables like this one line by line.

The third command is what makes a Linux machine a router. **`net.ipv4.ip_forward = 1` tells the
kernel to pass packets from one interface to another**; with 0, the same machine with the same two
cards is a host that happens to sit on two networks and refuses to carry anybody else's traffic.

Now pc1 pings one machine in its own network and one beyond the router:

```
ana@pc1:~$ ping -c 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=1.74 ms

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.738/1.738/1.738/0.000 ms
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=7.49 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 7.487/7.487/7.487/0.000 ms
ana@pc1:~$ traceroute -n 192.0.2.80
traceroute to 192.0.2.80 (192.0.2.80), 30 hops max, 60 byte packets
 1  10.20.10.1  2.879 ms  0.590 ms  0.248 ms
 2  203.0.113.1  1.140 ms  0.774 ms  0.723 ms
 3  192.0.2.80  1.474 ms  0.824 ms  0.695 ms
```

Compare the two `ttl` values. Every IP packet carries a **time to live**, a counter that each
router subtracts one from before passing the packet on; a packet whose counter reaches zero is
thrown away, which is what stops a packet circling for ever. The server at 10.20.10.10 answered
with `ttl=64`, the value Linux starts at, because no router stood between it and pc1. The answer
from 192.0.2.80 arrived with **`ttl=62`: two routers handled it on the way back**, r1 and the
provider.

`traceroute` names them. It sends packets with a time to live of 1, then 2, then 3, and each router
that throws one away says so. The first hop is **10.20.10.1**, r1's office address; the second is
**203.0.113.1**, the provider; the third is the destination itself. Three hops, two of them
routers, which is the same count the `ttl` gave.

The round trip to 192.0.2.80 took 7.49 ms against 1.74 ms inside the office, but this lab's cables
carry no delay at all, and both numbers measure one virtual computer doing all the work. What the
capture shows reliably is the count of routers, not the time.

Three things a router does that the switch section's device does not:

- **It separates networks.** A broadcast, such as ARP's question, stops at the router; lesson 18
  watches one fail to cross r1.
- **It drops what it has no route for**, rather than flooding it. A switch that does not know a
  destination sends the frame everywhere; a router with no matching line and no default route
  discards the packet and tells the sender.
- **It is where policy goes.** Because every packet between the office and the internet crosses
  r1, r1 is where the firewall rules of the firewall section live, and where NAT gives the office's
  private addresses one public one, which is lesson 11.
