---
title: Who is on the other end of the cable
version: 1
---

**A network port grants the network to whatever is plugged into it.** On an ordinary switch, the
moment a cable is connected, the device at the other end can send to every machine on the segment,
ask the DHCP server for an address and start talking. Lessons 1 and 2 hardened what each machine
runs. This lesson is about the question before that: which devices should be on the network at all,
and how the network can tell.

The wrong picture is that the network is inside the building and the building is locked, so what is
plugged in belongs there. Jatobá's reception has a wall socket behind a chair. A visitor's laptop, a
contractor's diagnostic box, a small device left behind a printer: none of them needs a password to
use that socket, and once on the segment each one can reach the portal's SSH, the file shares and
everything lesson 1 found listening.

**Network access control** (NAC) moves the decision to the switch port. Before forwarding a device's
traffic, the switch asks who the device is, and opens the port only to an answer it accepts. There
are two common ways to ask, and the lesson builds both on `sw`, the lab's switch:

| | the question | how much the answer proves |
|---|---|---|
| **MAC filtering** | is this hardware address on my list? | that the device claims that address |
| **802.1X** | can this device prove who it is with a credential? | that it holds a key or a password the network issued |

## The lab's switch

`sw` is a machine like the others, and its network namespace is the switch itself: a bridge called
`br0` and one port per machine, named after the machine plugged into it. A filter attached to
`port-desk` sees every frame `desk` sends, before the bridge forwards it anywhere. That is exactly the
position of a managed switch's port security, which is why the lab can show both methods for real.

Start the lab with `sudo bash hostlab.sh up desk web`, and open two shells: one on `sw` and one on
`desk`, both with `sudo bash hostlab.sh sh`. Every file the lesson writes lives in a directory `nac`
in your home on each machine.

Two things in this lesson are not in the lab. A real switch implements both methods in its firmware
and is configured through its own interface, which differs by vendor; the lab does it with the same
Linux tools a switch's firmware is often built on, `nftables` for the port filter and `hostapd` for
802.1X. And the lab has no RADIUS server: `hostapd` checks the credentials itself, where a real
network sends them to a central server. The last section says what changes, and none of the vendor or
RADIUS parts was run for this course.
