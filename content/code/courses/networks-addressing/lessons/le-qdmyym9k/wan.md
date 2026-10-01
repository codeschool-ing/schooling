---
title: The WAN, the links you rent
version: 1
---

A **WAN** (*wide area network*) joins sites that are too far apart for the company to run its own
cable, so **the links belong to somebody else**: a telecoms provider, an internet provider, a
company that sells a line between two cities. You pay for them every month, by capacity; you do not
see inside them; and when one fails, you open a ticket instead of walking to a cupboard.

In the lab the provider is a single router, `isp`. The head office's router `rhq` is cabled to it
on `203.0.113.0/30`, and the branch's router `rbr` on `198.51.100.0/30`. Those two small networks are
the WAN links: four addresses each, one end for the customer and one for the provider.

From pc1, the branch router's public address is three hops away:

```
ana@pc1:~$ traceroute -n 198.51.100.2
traceroute to 198.51.100.2 (198.51.100.2), 30 hops max, 60 byte packets
 1  10.20.10.1  17.309 ms  0.891 ms  0.474 ms
 2  203.0.113.1  5.080 ms  0.713 ms  0.553 ms
 3  198.51.100.2  2.681 ms  0.684 ms  0.628 ms
```

Hop 1 is `rhq`, the edge of pc1's LAN. Hop 2, `203.0.113.1`, is the provider's end of the head
office's link — the first router that does not belong to the company. Hop 3 is the branch router's
public address, on the provider's other link. The times are this lab's virtual machine, and the
first probe of each line is the slow one; they say nothing about a real WAN.

Now look at the provider from inside, which in a real network you would never be allowed to do:

```
root@isp:~# ip route
198.51.100.0/30 dev eth1 proto kernel scope link src 198.51.100.1 
203.0.113.0/30 dev eth0 proto kernel scope link src 203.0.113.1 
```

**The provider knows two networks: the two links it sold.** It has no route to `10.20.10.0/24` and
none to `10.30.10.0/24`. The company's LANs are invisible to it. That is not an oversight of the lab:
private addresses are used by thousands of companies at once, so no provider can route them. The
traceroute above worked only because `rhq` translated pc1's address into its own public one,
`203.0.113.2`, on the way out — NAT, which lesson 11 takes apart. Seen from the WAN, the whole head
office is one public address.

## The kinds of WAN link

A company buys one of three things, and the names are worth recognising:

- **A leased line** — a dedicated circuit between two points, the same capacity day and night,
  whether used or not. Simple and expensive.
- **MPLS** — a provider's private network that carries several customers' traffic apart from each
  other, with the provider routing between the customer's sites.
- **The internet** — an ordinary internet connection at each site, the cheapest by far, with the
  sites joined through it by a VPN. That is what the rest of this lesson builds.

None of the three was run in the lab beyond what the lab shows: one router playing the provider,
with two links.

## LAN against WAN

| | LAN | WAN |
|---|---|---|
| who owns the links | the company | a provider |
| cost of traffic | nothing beyond the equipment | a monthly fee, by capacity |
| reached by | a switch, directly | a router, through somebody else's network |
| in the lab | `10.20.10.0/24`, `10.30.10.0/24` | `203.0.113.0/30`, `198.51.100.0/30` |

**A WAN link is the slow, paid, unowned part of the path**, and design starts from that: keep
traffic on the LAN where you can, and decide what crosses the WAN on purpose.
