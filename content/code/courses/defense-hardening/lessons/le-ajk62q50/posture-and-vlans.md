---
title: VLANs, guests and the state of the device
version: 1
---

**Yes or no is the simplest answer an 802.1X server can give, and real networks rarely stop there.**
The server can also say *where* the device goes. Nothing in this section was run for this course:
it depends on managed switches that support VLAN assignment and on a RADIUS server, and it is taught
from the standards and from how vendors document the features. The names below are the common ones;
each vendor's interface has its own.

## Dynamic VLAN assignment

With the acceptance, a RADIUS server can return attributes, and three of them (`Tunnel-Type`,
`Tunnel-Medium-Type` and `Tunnel-Private-Group-ID`) tell the switch which **VLAN** to put the port
in. The same wall socket then gives a staff laptop the staff network and the reception printer, let
in by MAC authentication bypass, a printers-only network that reaches the print server and nothing
else. The decision follows the credential, not the socket, so moving a desk does not mean
reconfiguring a switch.

## Guests and failures

Two more outcomes are worth configuring on purpose:

- **a guest VLAN** for a device that does not speak 802.1X at all, a visitor's laptop, with internet
  access and no route to any internal machine;
- **an authentication-failure VLAN**, or simply nothing, for a device that tried and was refused.

Both are decisions about what a stranger gets. The safe default is the one the lab's port showed
before `desk` logged in: nothing but the login conversation.

## Posture

**Posture assessment** asks a second question after "who are you": "what state are you in?". A NAC
agent on the device reports whether the operating system is up to date, whether the disk is
encrypted, whether endpoint protection is running, and the server decides with that as well as the
credential. A device that is somebody's, and is out of date, can be put in a **remediation** network
that reaches only the update servers until it complies.

Posture is the point where network access control meets everything else in this course. The checks
it asks about are lesson 2's baseline, lesson 7's and lesson 8's protection, and lesson 17's patches.
Its weakness is the same as any agent's report: it is the device describing itself, which is an
assertion again, stronger than a MAC address because the agent is harder to imitate, and still
weaker than a certificate.

## Where this sits

802.1X controls who gets onto the segment. It says nothing about what a legitimate device does once
it is there, which is why the lessons around this one still harden the machines themselves. And it is
one control among several on the same question: the inventory of lesson 18 is the list the NAC
server's decisions should agree with, and a device the server let in that the inventory does not
know is a finding.
