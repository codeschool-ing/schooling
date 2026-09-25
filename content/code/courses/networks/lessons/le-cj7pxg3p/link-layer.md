---
title: Layers 1 and 2: a link and a hardware address
version: 1
---

Layer 1 is the physical signal: the cable, the radio, the light on the port. A terminal cannot see a
signal, but it can see what the network card makes of it:

```
ana@laptop:~$ ip link show eth0
106: eth0@if107: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:a8:0a:14 brd ff:ff:ff:ff:ff:ff link-netns wire
ana@laptop:~$ ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0@if107       UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

The flags between `< >` are the card's state. **`UP` means the interface was switched on, and
`LOWER_UP` means there is a signal from the other end**: a cable plugged into something powered, or a
Wi-Fi association. `UP` without `LOWER_UP` is the unplugged cable, and it is the first thing to rule
out, because nothing above it can work. `mtu 1500` is the largest packet this link carries, which
lesson 2 comes back to. (`link-netns wire` is the lab showing through: the other end of this cable
is in the lab's wiring.)

Layer 2 delivers a **frame** to one device on the same link, and names the device by its **MAC
address**: `52:54:00:a8:0a:14` for the laptop, six bytes written in hexadecimal and assigned to the
network card. A switch reads it to decide which port a frame leaves by. It means nothing beyond the
link, and no router ever forwards it.

The laptop knows the server's IP address, but a frame needs the server's MAC. It asks, with **ARP**
(*Address Resolution Protocol*). The laptop's neighbour table starts empty, and one ping fills it:

```
ana@laptop:~$ ip neigh
ana@laptop:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=64 time=0.358 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.358/0.358/0.358/0.000 ms
ana@laptop:~$ ip neigh
192.168.10.10 dev eth0 lladdr 52:54:00:a8:0a:0a REACHABLE 
```

Meanwhile, on the server, `tcpdump` printed every frame that arrived:

```
ana@server:~$ sudo tcpdump -n -e -i eth0 -c 4 arp or icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:05:53.343795 52:54:00:a8:0a:14 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.10 tell 192.168.10.20, length 28
13:05:53.343817 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:a8:0a:0a, length 28
13:05:53.343826 52:54:00:a8:0a:14 > 52:54:00:a8:0a:0a, ethertype IPv4 (0x0800), length 98: 192.168.10.20 > 192.168.10.10: ICMP echo request, id 21270, seq 1, length 64
13:05:53.343925 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype IPv4 (0x0800), length 98: 192.168.10.10 > 192.168.10.20: ICMP echo reply, id 21270, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Four frames. In the first, the destination MAC is **`ff:ff:ff:ff:ff:ff`, the broadcast address, which
every device on the link receives**, and the question is *who has 192.168.10.10, tell 192.168.10.20*.
Only the server answers, straight to the laptop: *192.168.10.10 is at 52:54:00:a8:0a:0a*. The answer
arrived 22 microseconds after the question, and the ping followed, addressed to that MAC. The table
keeps the answer as `REACHABLE`, so the next packet goes out without asking.
