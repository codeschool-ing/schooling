---
title: What the theorem says, and the picture to drop
version: 1
---

**CAP is a statement about one situation: the network between a system's machines has broken, and
every machine still running must choose between answering and being right.** It cannot be
guaranteed to do both. That is the whole theorem, and the rest of this lesson is what follows from
it for somebody who keeps data on more than one machine.

## The picture to drop first

The version most people meet is a triangle with three corners — Consistency, Availability,
Partition tolerance — and a slogan: *pick any two*. It suggests a menu, where a careful designer
might order C and A and leave P out.

**P is not on the menu.** A partition is not a feature a system has; it is something the network
does to it. Lesson 9 listed what one machine never had to deal with: messages that are lost,
clocks that disagree, a peer that is slow or dead and looks the same either way. The moment data
lives on two machines with a network between them, a cut link is going to happen, and the only
question left is what each machine does while it lasts. Eric Brewer, who put the conjecture
forward in 2000, wrote twelve years later that "two of three" had always been misleading: a system
only has to give something up while a partition lasts.

So read the theorem as a fork rather than a menu: **when a partition happens, choose C or A.** When
no partition is happening, CAP says nothing at all — and that silence is where the next idea,
PACELC, picks up in section 06.

## The three words, as the proof uses them

Seth Gilbert and Nancy Lynch proved Brewer's conjecture in 2002, and the proof needed each word to
mean one precise thing. All three mean less than they do in conversation.

| word | what it means in the theorem | what it does not mean |
|---|---|---|
| **consistency** | every read returns the most recent completed write, as though there were one copy; the name for this is *linearisability* | the C of ACID, which is about a transaction leaving the database's rules intact — `sql-databases` covers that one |
| **availability** | every request that reaches a machine still running gets an answer that is not an error | "the service was up 99.9% of the month", which is a measurement over time |
| **partition tolerance** | the system keeps working when any messages between its machines are lost | a promise that partitions will not happen |

The table carries a trap worth naming. Availability in CAP is about **every** running machine
answering. A system where the machines on one side of a cut keep working and the machine on the
other side returns errors is *not* available in CAP's sense, even though most of its users never
noticed anything. That system can be a perfectly good one; it has chosen consistency.

## At Roda Livre

Davi keeps the number of bicycles docked at each station on three machines, so that the app keeps
working when one of them is rebooted. Call them `n1`, `n2` and `n3`. On a normal day a change
reaches all three, and the app may read from any of them.

Then the link to `n3` is cut. A customer returns a bicycle to Rua XV, and her phone reaches `n3`.
`n3` cannot tell the others. It can refuse — the customer sees an error, and every answer anybody
reads stays true. Or it can accept — the customer is happy, and for a while `n3` and the other
two disagree about how many bicycles are at Rua XV. **There is no third option that keeps both**,
and the next section makes both of them happen on your machine.
