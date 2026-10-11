---
title: Why more than one machine
version: 1
---

**A distributed system is not a faster computer. It is several computers that have to agree with
each other over a network that does not always deliver.** The picture most people start with is
the first one: put more machines on the problem and it goes faster, in proportion. Sometimes it
does. What happens every time is that the second machine brings problems the first one never had,
and this lesson is mostly about those.

## Up or out

There are two ways to get more capacity than you have.

**Scaling up**, or vertical scaling, replaces the machine with a bigger one: more cores, more
memory, faster disks. Nothing in the software changes, which is its great virtue, and it stops at
the largest machine anybody sells. **Scaling out**, or horizontal scaling, adds more machines of
the same size. Its ceiling is far higher, and the price is that every program involved has to know
that there is more than one of them.

Four reasons push a team out rather than up:

- the data no longer fits on one machine's disks;
- the work no longer fits in one machine's time, and a report due at six in the morning needs ten
  machines working at once to finish by then;
- one machine is one failure, and when it stops, everything that depends on it stops;
- the people are far apart, and a copy of the data near them answers faster than one across an
  ocean.

Roda Livre has none of these problems. Its twelve stations and ninety bicycles produce data that a
laptop holds with room to spare, and Davi's rule is one machine until it hurts. You still need this
lesson, because the services a data team rents are distributed underneath: the warehouse of
`warehouse-modeling`, the object storage of `cloud`, a message log like the one in lesson 8. When
they behave strangely, the strangeness is usually this lesson's material showing through.

## Three things one machine never had

**A network that loses messages.** Inside one program, a function call either returns or raises.
Across a network, a request can be lost on the way there, the reply can be lost on the way back,
and either can arrive late. To the machine that sent the request, all of these look the same: no
answer yet. When the app asks the payments provider to charge a ride and hears nothing, it does not
know whether the customer was charged. Section 09 of this lesson is about what to do next.

**Clocks that disagree.** Every machine has its own clock, and synchronising them over the network
keeps them near the right time, not at it. Say the dock sensor at Largo da Ordem runs half a second
ahead of the app's server. A bicycle docks there and is taken again a moment later, and the sensor
stamps the docking at 08:00:00.400 while the server stamps the new unlock at 08:00:00.100: in the
data, the bicycle left before it arrived. Lesson 8 meets a cousin of this in a stream, where events
arrive in a different order from the one they happened in.

**Partial failure.** A single machine works or it does not. Five machines can have one dead, one
slow and three fine, all at once, and the three cannot be sure which of the other two is which. A
system built from them has to keep working through that, and section 08 shows why that is harder
than it sounds.

The rest of the lesson takes these in turn. **Partitioning** splits the data so that each machine
holds part of it. **Replication** copies each part to more than one machine, so that losing a
machine does not lose the data. **Fault tolerance** is everything that keeps the system answering
while some of it is broken. Lesson 10 asks the question all three lead to: when the network
splits the machines into two groups, what does the system give up?
