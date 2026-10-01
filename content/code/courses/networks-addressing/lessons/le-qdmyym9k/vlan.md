---
title: The VLAN, a LAN cut out by configuration
version: 1
---

The LAN section defined a LAN as the machines that reach each other directly, without a router.
In a small office that is simply every machine on the switch. But a company often wants **several
LANs in one building**, kept apart: the accounting PCs away from the visitors' Wi-Fi, the printers
and the phones each on their own. A separate switch for each group, with its own cable runs, would
work, and it multiplies the hardware by the number of groups.

A **VLAN** (*virtual LAN*) is the answer: **one switch divided into several LANs by configuration**.
Each port is assigned to a VLAN, and the switch forwards a frame only between ports of the same
VLAN. To the machines, it looks exactly like separate switches. pc1 in VLAN 10 and pc2 in VLAN 20
can sit on adjacent ports of the same switch and still need a router to reach each other, just as
pc1 and pc2 in the lab of this lesson need one.

That is lesson 3's distinction between the physical and the logical drawing, applied to a switch.
**The physical drawing is still one star. The logical drawing is several**, one per VLAN.

## Why the word belongs in this lesson

The other four words describe where a network is and who owns it. VLAN describes something else —
how one set of switches is divided — and it is here because in practice the five turn up together:

- a company's **LAN** is usually several **VLANs**;
- between two switches, one cable carries every VLAN at once, each frame marked with a 4-byte tag
  that says which VLAN it belongs to (the 802.1Q tag, lesson 19);
- a **VPN** can deliver a remote site into one particular VLAN, so that the branch's accounting
  PCs land in the head office's accounting network.

## What a VLAN is and is not

- **It is a broadcast boundary.** A broadcast in VLAN 10 — an ARP question, a DHCP request — never
  reaches VLAN 20. That keeps each LAN smaller and quieter (lesson 18 measures broadcast domains).
- **It is a place to filter.** Traffic between VLANs has to cross a router, and a router is where
  rules about who may talk to whom are written (lesson 22).
- **It is not a firewall by itself.** A VLAN separates traffic only as well as the switch is
  configured: a port left in the wrong VLAN, or a trunk carrying more VLANs than it should, joins
  what was meant to be apart. Lesson 19 shows how those mistakes look and how a switch is configured
  to refuse them.

The lab of this lesson has no VLANs; the `vlans` scenario of lesson 19 builds one switch with two,
and lesson 22 routes between them. For now, recognise the word: a VLAN is a LAN that exists because
somebody configured it, not because somebody pulled a cable.
