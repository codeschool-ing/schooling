---
title: The MTU a tunnel takes away
version: 1
---

An Ethernet link carries IP packets of up to **1500 bytes**, its MTU. A tunnel's packet has to fit in
that too, header included, so the packet inside can be at most 1500 minus the tunnel's overhead: **1480
for IP-in-IP, 1472 for GRE with a key**. That is why the tunnels in this lesson were given those MTUs.

A packet that is too big for the next link gets fragmented, split into pieces, unless its sender set the
**Don't Fragment** bit, which almost every TCP connection does. Then the router drops it and sends back an
ICMP message saying how big it may be. `ping -M do` sets the bit, and `-s` sets the size of the data, to
which ping adds 8 bytes of ICMP and 20 of IP. Through the IP-in-IP tunnel:

```
ana@laptop:~$ ping -c 1 -M do -s 1472 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 1472(1500) bytes of data.
From 192.168.10.1 icmp_seq=1 Frag needed and DF set (mtu = 1480)

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

ana@laptop:~$ ping -c 1 -M do -s 1452 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 1452(1480) bytes of data.
1460 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=0.606 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.606/0.606/0.606/0.000 ms
```

`hq`, `192.168.10.1`, refused the 1500-byte packet with **`Frag needed and DF set (mtu = 1480)`**.
The 1480-byte one went through. The laptop did not just print that message, it remembered it:

```
ana@laptop:~$ ip route get 192.168.20.30
192.168.20.30 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1001 
    cache expires 599sec mtu 1480 
```

For the next ten minutes, `599sec`, every packet the laptop sends to the till is sized for 1480. This is
**path MTU discovery**, and it works without anybody configuring anything, provided one thing: the ICMP
message has to reach the sender.

A firewall that drops all ICMP "for security" breaks exactly that. The big packet is dropped, the
message saying why is dropped too, and the sender keeps retrying a size that will never pass. Small
things work, a web page's first lines or a login screen, and anything large hangs with no error. It is
called a **PMTU black hole**, and lesson 21 finds one step by step. The fix there is the one used on
nearly every VPN router: rewrite the maximum segment size that TCP announces, so connections never try
to send packets that do not fit.

The overhead also has a price in throughput, smaller than people fear. Twenty-eight bytes on a
1500-byte packet is under 2%. On a stream of small packets, voice for instance, where each packet
carries 160 bytes of audio, the same 28 bytes are much more of the total, and a bandwidth plan that
forgets them is short.

The two tunnel interfaces show the arithmetic side by side:

```
ana@hq:~$ ip link show tun0; ip link show eth1
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1472 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 500
    link/none 
893: eth1@if894: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:00:71:02 brd ff:ff:ff:ff:ff:ff link-netnsid 1
```

`eth1`, the link to the ISP, carries 1500. `tun0`, the GRE tunnel over it, carries 1472, and `link/none`
says it has no hardware address at all.
