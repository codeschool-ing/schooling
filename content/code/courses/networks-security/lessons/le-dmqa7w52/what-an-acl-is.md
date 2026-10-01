---
title: An access list is a firewall with no memory, on an interface
version: 1
---

An **access control list** (ACL) on a router or a switch is an ordered list of *permit* and *deny*
lines, bound to one interface in one direction. Each packet crossing that interface in that direction
is compared with the lines from the top; the first line that matches decides; and a packet that matches
nothing is denied. Four properties set it apart from the firewall of lessons 1 to 5:

| property | an ACL | `fw`'s rule set |
|---|---|---|
| memory | none: every packet judged alone, like lesson 1's stateless filter | connection tracking |
| where it applies | one interface, one direction: *in* or *out* | a hook that sees every interface |
| when nothing matches | an **implicit deny** at the end, invisible in the configuration | the chain's `policy`, written down |
| where it runs | often in the switching hardware, at the full speed of the port | in software |

The last row is why ACLs survive. **They cost almost nothing to apply**, so they filter where a stateful
firewall would be too slow or too expensive: between VLANs on a core switch, on the internet edge of a
router, on the ports a management network is reached through.

The lab has no Cisco equipment, and the syntax in this lesson is Cisco IOS because most network
engineers meet ACLs there first. **The IOS configuration shown is notation, not run.** Beside each one,
the same ACL runs on `branch`, the branch office's Linux router, in nftables' `netdev` family: a chain
bound to one device on its **ingress** hook, before routing, with no connection tracking. That is as
close to a router's interface ACL as Linux gets, and every result in the lesson comes from it.
