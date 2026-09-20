---
title: The box in the hall, and the two machines inside it
version: 1
---

The thing the provider installed does at least three jobs, and they are three different machines
that happen to share a plastic case and a power supply. Knowing which is which is most of what
makes a home network fixable.

## The modem

**A modem converts.** On one side is whatever the street uses — a fibre strand, a coaxial cable,
a telephone pair — and on the other side is ordinary Ethernet. That is its whole job: the signal
that came down the road, turned into the signal a computer understands, and back again.

A modem has **one connection to the provider** and it either has it or it does not. That is why
its light is the first thing anybody looks at, and why *the modem light is red* is a sentence a
support line can act on immediately: nothing inside the house can cause it.

## The router

**A router decides where a packet goes.** Your house has many devices and one line to the street;
something has to sit in the middle, hand out addresses, keep track of which device asked for
what, and send each answer back to the one that asked.

That is the router, and it is the machine most of this lesson is about. It is also the one with
the settings page, the password, and the reset button.

## The access point

**An access point is the radio.** It is the part that turns a wired network into a wireless one,
and it is the part with the antennas — internal on most modern boxes, which is why they are
taller than they need to be.

The Wi-Fi name and the Wi-Fi password belong to this part. Nothing else in the box knows or cares
about them.

## Why the three are one box, and why that is a problem

Providers ship a combined unit because one box is cheaper to make, cheaper to support and simpler
to install. It is genuinely the right product for most homes.

The cost is that **a single failure has three possible causes and one set of lights**, and that
the settings page mixes three unrelated kinds of setting together: the line, the addressing, and
the radio. A great deal of home-network confusion is somebody changing a radio setting to fix a
line problem.

There is one practical consequence worth knowing now. If you ever buy your own router — usually
to get better Wi-Fi than the provider's box gives — you do **not** replace the modem. You put the
provider's box into what is variously called *bridge mode*, *modem mode* or *transparent mode*,
so that it stops routing and only converts, and let your own router do the rest. Two devices both
routing is the single most common cause of *it works but nothing can find anything else*.
