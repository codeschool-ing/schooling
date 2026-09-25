---
title: How big a packet can be
version: 1
---

Every link has a **MTU**, *maximum transmission unit*: the largest IP packet it carries in one frame.
On Ethernet it is 1500 bytes, and `ping` can test it. `-s` sets the size of the data, and `-M do` sets
the **don't fragment** flag, forbidding any router from cutting the packet into pieces:

```
ana@laptop:~$ ip link show eth0 | head -1
158: eth0@if159: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
ana@laptop:~$ ping -c 1 -M do -s 1472 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1472(1500) bytes of data.
1480 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.323 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.323/0.323/0.323/0.000 ms
ana@laptop:~$ ping -c 1 -M do -s 1473 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1473(1501) bytes of data.
ping: local error: message too long, mtu=1500

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms
```

1472 bytes of data, plus 8 of ICMP header and 20 of IP header, is exactly 1500, and it went through.
One byte more and the laptop refused to send it at all: `message too long, mtu=1500`.

Now the office line is changed to the kind many small offices have, DSL with **PPPoE**, which spends 8
bytes of every frame on its own header and leaves an MTU of **1492**. The same 1500-byte ping:

```
ana@laptop:~$ ping -c 2 -M do -s 1472 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1472(1500) bytes of data.
From 192.168.10.1 icmp_seq=1 Frag needed and DF set (mtu = 1492)
ping: local error: message too long, mtu=1492

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1006ms

ana@laptop:~$ ip route get 192.0.2.80
192.0.2.80 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1000 
    cache expires 597sec mtu 1492 
ana@laptop:~$ tracepath -n 192.0.2.80
 1?: [LOCALHOST]                      pmtu 1500
 1:  192.168.10.1                                          0.061ms 
 1:  192.168.10.1                                          0.005ms 
 2:  192.168.10.1                                          0.006ms pmtu 1492
 2:  203.0.113.1                                           0.449ms 
 3:  198.51.100.254                                        0.023ms 
 4:  192.0.2.80                                            0.111ms reached
     Resume: pmtu 1492 hops 4 back 4 
```

The first line of the answer is the important one. **The router could not send the packet on, was not
allowed to cut it, and said so**: `Frag needed and DF set (mtu = 1492)`, an ICMP message from
`192.168.10.1`. The laptop believed it. The second ping never left: `message too long, mtu=1492`. The
routing table now carries that limit for this destination, for the next ten minutes (`expires
597sec`), and `tracepath` finds the same thing hop by hop: the path MTU drops to 1492 at hop 2.

That exchange is **path MTU discovery**, and it runs without anybody noticing, every day, on every
connection. The next section is what happens when it cannot.
