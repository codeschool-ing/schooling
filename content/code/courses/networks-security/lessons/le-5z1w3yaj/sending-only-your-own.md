---
title: Sending only your own addresses
version: 1
---

The previous section protected the company from forged packets arriving. The same filter, pointed
the other way, protects **everybody else from forged packets leaving**. That direction has a name,
**BCP 38**, the best current practice that asks every network to drop outgoing packets whose source
address is not one of its own. If every network did, reflection attacks (lesson 6) would have no
forged questions to send.

`laptop` has been given a second address that belongs to nobody in the lab, `198.51.100.7`, and tries
to reach the internet with it:

```
ana@laptop:~$ nc -z -v -w1 -s 198.51.100.7 203.0.113.50 443
nc: connect to 203.0.113.50 port 443 (tcp) timed out: Operation now in progress
root@fw:~# nft list chain ip filter prerouting | grep "fib saddr"
		fib saddr . iif oif missing counter packets 1 bytes 60 drop comment "the source must be reachable back through the interface it came in on"
```

The same `fib` rule caught it: `fw` has no route to `198.51.100.7` through the LAN interface, so the
packet cannot have come from the LAN honestly, and the counter shows 1 packet dropped. Without the
forged address, `laptop` reaches the same port normally:

```
ana@laptop:~$ nc -z -v -w1 203.0.113.50 443
Connection to 203.0.113.50 443 port [tcp/https] succeeded!
```

**A compromised machine on the LAN is the realistic reason for this filter.** Software that has taken a
computer over may be told to take part in somebody else's flood, and forged sources are how a flood
hides. A network that refuses to send them makes its own machines useless for that, and makes the
attempt visible in a counter somebody can alert on.

Where the network hides its internal addresses behind one public address with NAT, the rule is
simpler still: after NAT, the only legitimate source towards the internet is that one address.
