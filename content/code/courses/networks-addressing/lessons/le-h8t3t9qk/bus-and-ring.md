---
title: Bus and ring, the shapes of a shared cable
version: 1
---

Before switches were cheap, a local network was **one shared medium**: a single cable, or a single
loop, that every machine used in turn. Two shapes came out of that, the bus and the ring. Neither
is built for an office any more, and neither was run in this course's lab, but both explain words
you still meet — *collision*, *terminator*, *token* — and both show the failure that the star was
adopted to avoid.

## The bus

In a **bus**, every machine taps onto one cable that runs past all of them. Early Ethernet was
exactly this: **10BASE5**, a thick coaxial cable up to 500 metres long, and later **10BASE2**, a
thinner one up to 185 metres, with a T-connector at each machine. Each end of the cable carried a
**terminator**, a resistor that absorbs the signal; without it the signal bounced back from the
open end and corrupted everything on the wire.

A bus is a broadcast by construction. A frame that one machine sends travels the whole cable, and
every machine reads it and keeps only what is addressed to it. Only one machine may transmit at a
time, so two that start together **collide**, both signals are garbled, and both try again after a
random wait. That rule is called CSMA/CD, and lesson 18 shows what a collision domain is and why
switches made it disappear.

**The bus fails as a whole.** A break anywhere in the cable leaves two open ends with no
terminator, the reflections ruin both halves, and every machine on it loses the network — not only
the ones beyond the break. A loose T-connector behind somebody's desk was enough, and finding it
meant walking the cable.

## The ring

In a **ring**, each machine is connected to exactly two neighbours and the connections close into
a loop. In the shared rings of the 1980s and 1990s, a frame travelled round the loop from machine
to machine until it came back to the sender.

**Token Ring** (IEEE 802.5) solved the collision problem with a rule: a small frame called the
**token** circulates, and only the machine holding it may transmit. No collisions, and a fair turn
for everybody. **FDDI** used two fibre rings running in opposite directions, so that a single
break could be healed by turning the traffic back along the second ring.

A plain ring has the bus's weakness in another form: **one break opens the loop**, and in a
single ring nothing goes round any more. That is why Token Ring was wired physically as a star,
with every station cabled to a central box that joined the loop internally and closed it again
when a station was unplugged — the logical ring, the physical star of the previous section.

## What is left of them

Inside buildings, both lost to Ethernet over a star of switches, for reasons the next section puts
in the lab. The ideas survive elsewhere:

- **Rings** are alive in metropolitan fibre, where a provider loops fibre round a city so that a
  cut cable can be bypassed the other way round. Lesson 4 meets them under the name MAN, and the
  ring in this lesson's lab is a modern version: a ring of routers, each cable its own link, which
  is not a shared medium at all.
- **Buses** are alive in machines that are not computer networks in this course's sense: the CAN
  bus that joins the control units of a car is one shared pair of wires with a terminator at each
  end.

If you find coaxial Ethernet in a working office today, the useful sentence is that it is a single
point of failure the length of the building.
