---
title: GRE, and what four more bytes buy
version: 1
---

**GRE, Generic Routing Encapsulation, puts a small header of its own between the outer IP header and
the payload.** It is IP protocol 47. The header's main field names what is inside, so GRE can carry
things IP-in-IP cannot: IPv6, multicast from a routing protocol like OSPF, or Ethernet frames. That
flexibility is why most site-to-site links between routers from different vendors were GRE for two
decades, often with IPsec around it, the subject of lesson 2.

On a Linux router it is one command. On the kernel these transcripts were recorded on, it fails:

```
ana@hq:~$ sudo ip link add gre1 type gre local 203.0.113.2 remote 198.51.100.2 key 42
Error: Unknown device type.
```

`Unknown device type` means that kernel has no GRE module, not that the command is wrong. On your
Ubuntu the same command prints nothing and creates a tunnel called `gre1`, which this lesson does not
use: remove it with `sudo ip link del gre1`, so that the only tunnel on `hq` is the one below.

The course runs `tunnel.py` again, in GRE mode, with the same addresses and a key of 42. The IP-in-IP
tunnel goes first, at both ends. Each `tunnel.py` has to be stopped on its own machine, which is what
`netlab.sh kill` does, typed on the virtual machine; when the program exits, its `tun0` disappears and
the route through it goes too. Then the new tunnel, on `hq` and on `branch`:

```
ana@netlab:~$ sudo bash netlab.sh kill hq tunnel.py; sudo bash netlab.sh kill branch tunnel.py
ana@hq:~$ sudo setsid tunnel.py gre tun0 203.0.113.2 198.51.100.2 42 & sleep 1; sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.20.0/24 via 10.0.0.2
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 2 ip proto 47
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 22377, offset 0, flags [DF], proto GRE (47), length 112)
    203.0.113.2 > 198.51.100.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 39025, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.168.20.30: ICMP echo request, id 31773, seq 1, length 64
IP (tos 0x0, ttl 63, id 11888, offset 0, flags [DF], proto GRE (47), length 112)
    198.51.100.2 > 203.0.113.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 41473, offset 0, flags [none], proto ICMP (1), length 84)
    192.168.20.30 > 192.168.10.20: ICMP echo reply, id 31773, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

Three layers now. The outer packet is **112 bytes** with `proto GRE (47)`. Inside it, GRE reports
`length 92` and `key=0x2a`, which is 42 in hexadecimal. Inside that, the same 84-byte ping as before.
**112 − 84 = 28 bytes of tunnel**: 20 of outer IP and 8 of GRE, of which 4 are the key. The tunnel's MTU
went from 1480 to 1472 for the same reason.

## What the key is for

**A GRE key tells two tunnels between the same pair of addresses apart.** Two routers can run several
GRE tunnels at once, for different customers or different routing domains, and the outer headers would
be identical. The key is how each packet says which tunnel it belongs to.

It is not a password. It travels in clear text, `tcpdump` printed it, and anybody on the path can read
it and copy it. What it does do is make a mismatch fail. Restart `branch`'s end with a key of 43 while
`hq` keeps 42, ping from the laptop, then put 42 back and ping again:

```
ana@netlab:~$ sudo bash netlab.sh kill branch tunnel.py
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 43 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1022ms

ana@netlab:~$ sudo bash netlab.sh kill branch tunnel.py
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@laptop:~$ ping -c 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=1.58 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.576/1.576/1.576/0.000 ms
```

With the wrong key, **nothing reports an error**. The packets arrive at `branch`, `branch` sees a key it
does not expect and drops them, and the laptop only sees silence. That silence is the usual symptom of
a tunnel whose two ends disagree about something, and lesson 4 meets it again with WireGuard.

| | IP-in-IP | GRE |
|---|---|---|
| IP protocol | 4 | 47 |
| bytes added | 20 | 24, or 28 with a key |
| carries | IPv4 only | IPv4, IPv6, multicast, Ethernet |
| tells tunnels apart | no | yes, by key |
| encrypts | no | no |
