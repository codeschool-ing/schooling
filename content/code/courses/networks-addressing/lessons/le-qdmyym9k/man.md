---
title: The MAN, a network the size of a city
version: 1
---

A **MAN** (*metropolitan area network*) sits between the other two: bigger than one site, smaller
than a country, and usually the size of one city or one metropolitan region. It is the least
precise of the five words, and you will meet it more often on a provider's price list than in a
company's own diagrams.

Three things get called a MAN, and they are worth telling apart:

- **A provider's metropolitan network.** A provider lays fibre round a city — very often as a
  **ring**, the shape lesson 3 cut and watched recover — and sells connections to the buildings on
  it. For the provider it is part of its own network. For the customer it is a WAN link with a short
  distance and a high speed.
- **Metro Ethernet.** A service built on that fibre that delivers ordinary Ethernet between two or
  more of the customer's buildings in the same city. From the customer's side, the far building
  looks as if it were at the end of a very long cable, and the two sites can even share one LAN.
- **One organisation's network across a city.** A city government joining its schools and
  hospitals, or a university joining campuses in different districts, sometimes on fibre it owns
  and sometimes on fibre it rents.

**Ownership decides which of the earlier words applies**, just as in the WAN section. A university
that owns its fibre between campuses operates something that behaves like a very large LAN; a
company that rents metro Ethernet from a provider is buying a WAN link that happens to be short and
fast. The word MAN describes the distance more than the arrangement.

The term also lives in the name of the standards body behind Ethernet and Wi-Fi: the **IEEE 802
LAN/MAN Standards Committee**. That is why "LAN/MAN" turns up in standards documents more often than
anywhere else.

## What the lab does not show

Nothing in this course's lab is a MAN. A city's worth of fibre has no useful imitation on one
computer, and none was attempted. What the lab can show is the one property that makes metropolitan
fibre worth building as a ring — two ways out of every building. Lesson 3 measured it: the ring
lost 19 of 30 pings when a cable was cut, and then carried on round the other side.

When a support ticket says "the link to the other building is down", the useful first question is
the one this lesson keeps asking: **whose link is it?** If it is the company's own fibre, the fault
is yours to find. If it is a provider's metro service, the next step is the provider's ticket
number, and the evidence you collect — a traceroute that stops at your own router, a link light that
went out at a known minute — is what makes that ticket move.
