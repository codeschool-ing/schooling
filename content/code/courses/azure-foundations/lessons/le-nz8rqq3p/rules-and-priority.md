---
title: Rules, priorities and the six you did not write
version: 1
---

**A network security group, an NSG, is an ordered list of rules that allows or denies traffic, and
it does nothing until it is attached to a subnet or to a machine's network interface.** Each rule
names a direction, a source, a destination, a port, a protocol and an action, and carries a
**priority**: a number between 100 and 4096. For each new connection Azure reads the rules of the
right direction from the lowest number up, and **the first rule that matches decides**. Nothing
after it is read.

That last sentence is where the usual wrong picture breaks. People read a list of firewall rules as
a sum, as if a deny anywhere in the list wins; an NSG is read like a queue, and a deny at 4000 never
sees a packet that an allow at 100 already let through. Two rules with the same priority and
direction cannot exist in one NSG, so the order is always defined.

## The rules every NSG starts with

An NSG is never empty. Azure puts **three default rules in each direction**, at priorities no rule of
yours can reach, and they cannot be deleted, only overruled by a rule with a lower number:

| direction | priority | name | from | to | action |
|---|---|---|---|---|---|
| inbound | 65000 | `AllowVnetInBound` | `VirtualNetwork` | `VirtualNetwork` | allow |
| inbound | 65001 | `AllowAzureLoadBalancerInBound` | `AzureLoadBalancer` | any | allow |
| inbound | 65500 | `DenyAllInBound` | any | any | deny |
| outbound | 65000 | `AllowVnetOutBound` | `VirtualNetwork` | `VirtualNetwork` | allow |
| outbound | 65001 | `AllowInternetOutBound` | any | `Internet` | allow |
| outbound | 65500 | `DenyAllOutBound` | any | any | deny |

Read them as one sentence: **anything inside the network may talk to anything inside the network,
nothing from outside may come in, and everything may go out to the internet.** Two of those three are
right for almost nobody. The first lets a compromised web server open a connection to the database
on any port; the third lets anything that runs on a machine send the shop's data anywhere. The rules
you write exist mainly to narrow those two.

## Where an NSG is attached, and the order of two

An NSG can be attached to a **subnet**, to a **network interface**, or to both. Attached to a subnet,
it judges every machine in it; attached to an interface, only that machine. With both, a packet
meets two lists:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l17-order\" aria-label=\"The order in which two network security groups judge a packet when one is attached to the subnet and one to the network interface. Inbound, a packet from the network passes the subnet's NSG first and the interface's NSG second before reaching the machine. Outbound, a packet from the machine passes the interface's NSG first and the subnet's NSG second. A deny in either stops it.\"><defs><marker id=\"l17-order-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">inbound</text><rect x=\"110.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the network</text><path d=\"M236.0 70.0 L258.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">subnet NSG</text><path d=\"M386.0 70.0 L408.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"410.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface NSG</text><path d=\"M536.0 70.0 L558.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the machine</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">outbound</text><rect x=\"110.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the machine</text><path d=\"M236.0 170.0 L258.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface NSG</text><path d=\"M386.0 170.0 L408.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"410.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">subnet NSG</text><path d=\"M536.0 170.0 L558.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the network</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">both must allow; a deny in either one stops the packet</text></svg>", "caption": "Inbound the subnet is read first; outbound the interface is."}
```

**Inbound, the subnet's NSG is read first and the interface's second; outbound, the other way
round.** A packet must be allowed by both to pass, and a deny in either one stops it. Microsoft's
own advice is to choose one level and keep to it, because two lists that each look right can
together deny what nobody meant to deny, and the person debugging it reads one of them. The shop
attaches its NSGs to subnets, one per tier, which matches lesson 16's rule that a subnet is the unit
of a policy.

## Stateful, and only for new connections

**An NSG remembers the connections it allowed.** If a machine opens a connection out to port 443,
the answer comes back in without any inbound rule saying so, because Azure keeps a record of the
flow. The same is true the other way: an inbound connection allowed on 8080 needs no outbound rule
for its replies. A rule is about who may start a conversation.

And a rule applies to **new** connections. Removing the rule that allowed an SSH session does not cut
the session already open; the next attempt is the one refused. That matters on the day a rule is
changed to shut somebody out: what is already connected stays connected until it ends or the machine
is restarted.
