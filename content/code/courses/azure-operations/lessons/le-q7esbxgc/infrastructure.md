---
title: What every public address already has
version: 1
---

**A distributed denial of service attack tries to exhaust something**: the bandwidth into a network, the
connection tables of a load balancer, or the threads of an application. It is distributed because it comes
from thousands of machines at once, usually other people's computers taken over for the purpose, which is
why blocking an address does nothing.

It is useful to split attacks by the layer they exhaust:

| layer | what floods | who stops it |
|---|---|---|
| **3 and 4**, network and transport | packets: UDP floods, SYN floods, reflection | Azure's DDoS protection, at the network edge |
| **7**, application | well-formed HTTP requests, many of them, to expensive pages | the WAF of lesson 18, rate limits, caching |

**Every public IP address in Azure is covered by DDoS infrastructure protection**, at no charge and with
nothing to configure. It defends Azure's own platform, and so defends you as a side effect: it is tuned to
volumes that would hurt Azure, not to what would hurt one shop. A flood well below Azure's thresholds can
still take down a small application, and infrastructure protection will not notice it.

That gap is what the paid plans close. Before reaching for them, notice where the shop's traffic arrives:
**Front Door**, at Microsoft's global edge, absorbs volumetric attacks across its whole network, far from
`brazilsouth`, and its WAF handles layer 7. For a site whose only public entry is Front Door, the regional
public addresses that a paid plan protects may not exist at all, which is the first question of the last
section.
