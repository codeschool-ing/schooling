---
title: Layer 3: an address and a route
version: 1
---

Layer 3 gets a packet to the right machine across networks, and its address is the **IP address**.
The laptop has one, with a prefix length after the slash:

```
ana@laptop:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if107       UP             192.168.10.20/24 
```

`192.168.10.20/24` says two things. The address is `192.168.10.20`, and the first 24 bits,
`192.168.10`, name the **network** it belongs to. Every address that starts with `192.168.10` is on
the same link and is reached directly, with ARP, as the server was. Anything else is not, and goes to
a **router**. (Working with prefixes is the subject of the networks-addressing course; here, `/24`
means "the first three numbers match".)

Which router is the **routing table**'s answer:

```
ana@laptop:~$ ip route
default via 192.168.10.1 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
ana@laptop:~$ ip route get 192.0.2.80
192.0.2.80 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1000 
    cache 
ana@laptop:~$ ping -c 3 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.413 ms
64 bytes from 192.0.2.80: icmp_seq=2 ttl=61 time=0.104 ms
64 bytes from 192.0.2.80: icmp_seq=3 ttl=61 time=0.105 ms

--- 192.0.2.80 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2028ms
rtt min/avg/max/mdev = 0.104/0.207/0.413/0.145 ms
```

Two lines, read from the most specific. `192.168.10.0/24 dev eth0` is the office: send it straight
out. `default via 192.168.10.1` is everything else: hand it to the **gateway**, the office router.
`ip route get` asks the table about one address, and for the web server the answer is *via
192.168.10.1*.

**The ping crossed routers, and the TTL says how many.** A packet leaves with a *time to live*, 64
on Linux, and each router takes one off before forwarding it. The reply from the server in the office
arrived with `ttl=64`, having crossed none; the reply from `192.0.2.80` arrived with `ttl=61`, so it
crossed three. A packet whose TTL reaches zero is dropped, which is what stops one from circling
forever when routes form a loop.

`traceroute` uses that rule to name the routers. It sends packets with a TTL of 1, then 2, then 3,
and each router that drops one says so:

```
ana@laptop:~$ traceroute -n 192.0.2.80
traceroute to 192.0.2.80 (192.0.2.80), 30 hops max, 60 byte packets
 1  192.168.10.1  0.235 ms  0.009 ms  0.004 ms
 2  203.0.113.1  0.547 ms  0.108 ms  0.296 ms
 3  198.51.100.254  0.283 ms  0.181 ms  0.201 ms
 4  192.0.2.80  0.301 ms  0.184 ms  0.103 ms
```

Four lines: the office router, the provider's router, a router in the provider's core, and the web
server itself, each timed three times. The times are the lab's, one computer talking to itself; on a
real connection the second line alone would take several milliseconds.
