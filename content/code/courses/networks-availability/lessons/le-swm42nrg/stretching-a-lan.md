---
title: When stretching a LAN is worth it, and when it hurts
version: 1
---

The ARP broadcast crossing the ISP is the feature and the danger in one packet. **A layer 2 VPN does not
join two networks; it makes them one, with everything a single segment shares.**

Stretching earns its place in a few situations. A virtual machine moved live from one data centre to
another keeps its IP address and its open connections only if the same subnet exists on both sides. Some
old applications find their peers by broadcast, or insist that a cluster's members sit on one subnet.
And a data centre interconnect, where both ends belong to one operator on links it owns, is what VXLAN
was built for.

Everywhere else, what the offices share is what they suffer together:

| shared | what it means across a WAN |
|---|---|
| broadcasts | every ARP request and DHCP discover at one site crosses the tunnel to every other site |
| a loop | a cable plugged back into its own switch at one site floods the other sites too |
| spanning tree | one tree across the WAN, lesson 20 of `networks-addressing`: a topology change at one site reaches the others |
| one subnet | if the WAN link fails, the subnet splits in two halves that each believe they are whole |
| one gateway | a machine moved to the branch still sends to its gateway at head office, and back, across the WAN |

The last row has a name, **tromboning**: traffic between two machines in the same building goes out
across the WAN to a router in the other one and comes back, because that is where the subnet's gateway
lives. **The split in the row above it is worse, because nothing reports it**: each half keeps answering
for the addresses it still has.

**Route when you can, stretch only when something needs the same subnet in two places.** Every tunnel
in lessons 1 and 2 joined two subnets through two routers. A broadcast storm or a loop at one office
stayed at that office, and a failed link cut one route rather than splitting one network into two
halves.

## The other ways to carry layer 2

None of these was run in the lab. The first three carry Ethernet frames, like VXLAN; the last is how
VXLAN is run at scale.

| | how it carries frames | where it is met |
|---|---|---|
| OpenVPN with `dev tap` | Ethernet frames over the same TLS VPN as this lesson | small setups, a remote bridge to one LAN |
| L2TPv3 | frames in IP or UDP, a pseudowire between two routers | a provider's point-to-point Ethernet service |
| VPLS | frames over a provider's MPLS network, many sites in one segment | carrier "LAN services" between branches |
| EVPN | BGP tells each end which MAC lives where, instead of flooding to learn it | data centres running VXLAN at scale |

EVPN answers the flood list of the last section. Rather than copying every broadcast and unknown frame
to every site and learning addresses from the replies, each end announces its own MAC addresses in BGP,
the protocol of lesson 17 of `networks-addressing`. The others know where an address lives before they
need to ask. 
