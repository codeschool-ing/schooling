---
title: IP: the address that moves
---

The **IP address** says where the machine is on the network — and, like a postal address, it describes a position, not an object. Take the laptop to another network and its IP changes.

IPv4 has four numbers from 0 to 255 (`192.168.0.10`) and offers only 4.3 billion combinations, which ran out. IPv6 solves it with 128 bits (`2001:db8::1`) — space that does not run out under any foreseeable scenario.

In the meantime, **private** ranges (`10.x.x.x`, `172.16–31.x.x`, `192.168.x.x`) are reused inside every local network and do not exist on the internet. The router does the translation (NAT) — which is why your machine sees itself as `192.168.0.10` while a website sees your provider's public IP.
