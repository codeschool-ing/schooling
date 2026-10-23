---
title: Four levels, asked in order
version: 1
---

**IAF's abstraction levels separate the reasons for a change from its requirements, its design and
its realisation, and insist that they are worked out in that order.** Each level answers one
question, and each answer is the input to the next.

| level | the question | what it produces |
| --- | --- | --- |
| **contextual** | *why?* | the drivers, goals, principles and scope of the change |
| **conceptual** | *what?* | the requirements: the services and information needed, independent of how they are provided |
| **logical** | *how?* | a solution design in logical components, independent of products |
| **physical** | *with what?* | the real products, platforms and standards that implement the logical design |

## Carcará's digital boarding, down one column

Take the information systems area and walk down the four levels for the programme of lesson 8:

1. **Contextual, why.** The board's goal: every passenger boards with a digital ticket by the end of
   2027. The principle *boarding works without a network*. The constraint *Frota stays*.
2. **Conceptual, what.** A ticket validation service that answers within a second with or without a
   network; a ticket issuing service for counters; a ticket list per trip available before departure.
   No product is named.
3. **Logical, how.** A validation component on the driver's device holding a per-trip list; a sync
   component that publishes lists and collects scans; ticketing as the single issuer of tickets, with
   a counter channel. Still no product.
4. **Physical, with what.** The boarding app on Android phones with SQLite; the boarding sync service
   in Go in the existing cloud region; the passenger web app's counter mode on station tablets.

Every element at a lower level answers to one above it. **The SQLite store exists because of the
logical validation component, which exists because of the conceptual service, which exists because
of the principle and the goal.** Remove the goal and the whole column can be questioned; change the
product and nothing above it moves.

## Logical is the level people skip

The temptation is to go straight from *what* to *with what*: from *we need offline validation* to
*SQLite on Android*. The logical level seems like a redundant step. It earns its place in two
situations:

- **when there is more than one physical option**: Carcará's drivers have Android phones today, and
  the logical design is what stays true if the phones are replaced by handheld validators in 2028;
- **when the same logical design is implemented in several places**: the counter mode and the
  passenger app are two physical realisations of one logical issuing channel.

It is the same distinction as lesson 8's architecture and solution building blocks. **Logical is
what; physical is which product.** A framework that names the boundary makes it harder to cross
without noticing.
