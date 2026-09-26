---
title: Isolated, from inside
version: 1
---

The isolated guest:

```
ana@vmi:~$ ip -br addr show enp1s0; ip route
enp1s0           UP             10.10.10.37/24 metric 100 fe80::5054:ff:fe6a:fd82/64 
10.10.10.0/24 dev enp1s0 proto kernel scope link src 10.10.10.37 metric 100 
10.10.10.1 dev enp1s0 proto dhcp scope link src 10.10.10.37 metric 100 
ana@vmi:~$ curl -sS -m 5 http://10.0.0.50/
curl: (7) Failed to connect to 10.0.0.50 port 80 after 6 ms: Couldn't connect to server
ana@vmi:~$ nc -zv -w 3 10.10.10.1 53
Connection to 10.10.10.1 53 port [tcp/domain] succeeded!
```

vmi has `10.10.10.37` from libvirt's DHCP, and its routing table has **no `default via` line** at all: it
knows its own network and nothing past it. The printer is out of reach, and so is everything else off
`10.10.10.0/24`. This is what a lab wants for a machine that must not touch anything real, such as a
target that is going to be attacked on purpose, lesson 14.

But one thing on the list answered: **`10.10.10.1` port 53, the host.** An isolated network is
isolated from the world, not from the host: the host has an address on it, libvirt's DHCP and DNS server
listens there, and so does anything else the host runs on every address. For most labs that is fine;
for a guest running something hostile, it is a door into the one machine that holds all the others.
Lesson 15 closes it.

The fourth mode of the table, **internal** or **private**, removes even that: a network with no address
for the host, where the guests can only reach each other. It also has no DHCP, so every guest on it
needs an address set by hand.
