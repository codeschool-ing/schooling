---
title: Where the model is loose
version: 1
---

The OSI model is a map, and real protocols do not always stay inside its lines:

- **ARP sits between layers 2 and 3.** It carries IP addresses in a layer 2 frame, and it exists
  only to join the two.
- **DNS is layer 7**, an application protocol like any other, and yet almost every other application
  depends on it before it can send its first byte.
- **TLS does the work of layers 5 and 6**, and runs inside the application, on top of TCP.
- ICMP, which carries `ping` and the messages `traceroute` reads, is part of layer 3 even though it
  travels inside an IP packet as if it were layer 4.

None of that makes the model wrong. It is a vocabulary, and people who work on networks use it every
day: a *layer 2 switch* forwards by MAC address, a *layer 3 switch* also routes, a *layer 4 load
balancer* spreads connections by port, a *layer 7 firewall* reads the HTTP inside them. **When
somebody says "it is a layer 2 problem", they mean the link, the MAC or ARP, and nothing above.**

The protocols that actually run the internet were designed with a simpler model of their own,
four layers instead of seven. Lesson 2 draws it next to this one.
