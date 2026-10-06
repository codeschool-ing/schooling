---
title: Segmenting the inside
version: 1
---

The lab has four segments because the shop is small. A real organisation divides its inside further,
and **segmentation** is the general name for splitting a network into zones with controlled paths
between them. The DMZ is one segment; the same idea applied everywhere else is what keeps one
compromised machine from becoming a compromised company.

### What to separate

Machines go in the same segment when they have the same exposure and the same value, and in
different segments when one should not be able to reach the other freely:

| segment | what is in it | why it is separate |
|---|---|---|
| public services (DMZ) | the shop's web server | most exposed, most likely to be compromised |
| servers | the database, the file server | most valuable |
| staff | laptops and desktops | they read email and browse, which is how attackers get in |
| management | the machines administrators work from | they hold the keys to everything else |
| guests and devices | visitors' Wi-Fi, printers, cameras, the card machine | nobody controls what runs on them |

The guests-and-devices row catches people out. A printer, a smart TV in the meeting room or a
camera runs software its owner never updates and cannot inspect. On a flat network it sits beside
the database. In its own segment, with a rule that lets it reach nothing it does not need, its
weakness stays its own.

### North-south and east-west

Traffic crossing the perimeter, between the inside and the internet, is called **north-south**.
Traffic between machines inside the network is **east-west**. The perimeter sees north-south and
nothing else. Most of what an attacker does after getting in, looking around, moving from one
machine to the next, reaching the database, is east-west, and a network that only filters at its
edge never sees it.

Segmentation puts filtering points on the east-west paths. In the lab, `fw` happens to sit between
all four segments, so the same device does both jobs. In larger networks, segments are often
**VLANs**, separate virtual networks sharing the same switches, with a firewall or a router with
rules between them.

### How far to go

Every boundary is a rule set to write and keep correct, so segmentation has the same cost as any
other layer from lesson 4. A sensible order for a small organisation is the table above, top to
bottom: get the public services into a DMZ first, then separate the valuable servers from the staff
machines, then the devices nobody controls.

Taken to its limit, segmentation stops being about zones at all: every workload gets its own
boundary, and every connection between two of them has to be allowed explicitly. That is
**microsegmentation**, and it is one of the ideas lesson 7 builds Zero Trust from.
`networks-security` lessons 4 and 21 go further with both, for students on a track that includes
it.
