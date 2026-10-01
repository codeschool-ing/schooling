---
title: Broadcast, one packet to everybody
version: 1
---

A **broadcast** address delivers one packet to every machine on a network at once. IPv4 has two
kinds. The **directed broadcast** of a network is its last address, the one with every host bit set
to 1: for `10.20.10.0/24` that is `10.20.10.255`, the `Broadcast` line ipcalc printed in this
lesson's first section. The **limited broadcast**, `255.255.255.255`, means every machine on this
link, whatever the network is, and it is what a machine with no address yet uses to ask for one;
lesson 10 watches a DHCP client do it.

pc1 needs only its own address and mask to work out the directed broadcast: the host part is the
last eight bits, and eight ones make 255.

```
ana@pc1:~$ ip addr show eth0 | grep "inet "
    inet 10.20.10.21/24 scope global eth0
ana@pc1:~$ ping -b -c 2 10.20.10.255
WARNING: pinging broadcast address
PING 10.20.10.255 (10.20.10.255) 56(84) bytes of data.

--- 10.20.10.255 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1022ms

```

`ping -b` is required because ping refuses a broadcast address without it, and the `WARNING` line is
ping making sure you meant it. Two requests went out and **nothing came back, 100% packet loss**. The
wrong conclusion is that the request never reached anybody. It reached every machine on the switch;
every one of them decided not to answer. Linux ignores an echo request sent to a broadcast address
unless told otherwise, and pc2 says so:

```
ana@pc2:~$ sysctl net.ipv4.icmp_echo_ignore_broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1
root@pc2:~# sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_echo_ignore_broadcasts = 0
root@pc3:~# sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_echo_ignore_broadcasts = 0
```

`icmp_echo_ignore_broadcasts = 1` is the default. Root on pc2 and on pc3 turned it off, the one setting
in this office changed from its default, and only for this demonstration. Same
ping again:

```
ana@pc1:~$ ping -b -c 2 10.20.10.255
WARNING: pinging broadcast address
PING 10.20.10.255 (10.20.10.255) 56(84) bytes of data.
64 bytes from 10.20.10.23: icmp_seq=1 ttl=64 time=5.82 ms
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=5.84 ms
64 bytes from 10.20.10.23: icmp_seq=2 ttl=64 time=1.65 ms

--- 10.20.10.255 ping statistics ---
2 packets transmitted, 2 received, +1 duplicates, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.646/4.435/5.837/1.972 ms
```

Now pc3 (`.23`) and pc2 (`.22`) both answered the first request. ping counts one answer per request
as received and **each extra answer to the same request as a duplicate**, so three replies to two
requests come out as `2 received, +1 duplicates`. pc2 did not answer the second request in this run,
and the capture does not show why. srv and r1 kept the default and stayed silent, as they did the
first time.

Why is ignoring broadcast pings the default? Because **a directed broadcast once let one packet turn
into hundreds**. In the late 1990s an attacker could send echo requests to the broadcast address of
somebody else's network, with a forged source address: the victim's. Every machine on that network
answered the victim, and a large network multiplied each packet many times over. These were called
smurf attacks, and two defaults ended them. **Routers stopped forwarding directed broadcasts that
arrive from outside** (RFC 2644, 1999, made that the required default), and operating systems
stopped answering broadcast pings, which is the setting above. Both are still the defaults, and a
network where either has been changed is worth asking about.

A broadcast also stops at the router whatever the settings. pc1's broadcast reached pc2, pc3, srv
and r1's `eth0`, and went no further: **the set of machines one broadcast reaches is a broadcast
domain**, and in this office it is everything plugged into sw1. Lesson 18 measures one, and lesson
19 splits a switch into several with VLANs.

Broadcasts are not a curiosity. ARP asks its question by broadcast, as the networks course showed
on the wire, and DHCP starts with one. Every machine in the domain receives every one of them and
spends a little effort deciding to ignore it, which is one reason a network of thousands of
machines is cut into smaller ones rather than built as one flat LAN.
