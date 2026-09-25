---
title: Ticket: "the internet is down"
version: 1
---

The laptop cannot reach anything. The first error is about a name, and it is misleading:

```
ana@laptop:~$ ping -c 2 www.example.com
ping: www.example.com: Temporary failure in name resolution
ana@laptop:~$ ip -br addr show eth0
eth0@if749       UP             192.168.10.20/24 
ana@laptop:~$ ip route
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
ana@laptop:~$ ping -c 2 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.490 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.125 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1009ms
rtt min/avg/max/mdev = 0.125/0.307/0.490/0.182 ms
ana@laptop:~$ ping -c 2 192.0.2.80
ping: connect: Network is unreachable
ana@laptop:~$ sudo ip route add default via 192.168.10.1
ana@laptop:~$ ping -c 2 www.example.com
PING www.example.com (192.0.2.80) 56(84) bytes of data.
64 bytes from www.example.com (192.0.2.80): icmp_seq=1 ttl=61 time=0.257 ms
64 bytes from www.example.com (192.0.2.80): icmp_seq=2 ttl=61 time=0.117 ms

--- www.example.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.117/0.187/0.257/0.070 ms
```

`Temporary failure in name resolution` sounds like DNS. Climbing the ladder says otherwise. The
interface is `UP` with its address. `ip route` has only the office network, `192.168.10.0/24`, and **no
`default via` line**: the laptop knows no way off its own network. The gateway answers a `ping`, so the
cable and the router are fine. `192.0.2.80` fails at once with `Network is unreachable`: that is the
laptop's own kernel refusing, because it has no route to send the packet on.

The DNS error was a consequence. The DNS server, `198.51.100.53`, is off the office network too, and
could not be reached either. Adding the default route back fixed both. **On a real PC the route comes
from DHCP**, so the fix is usually to renew the lease or remove a hand-typed setting, rather than an
`ip route` command.
