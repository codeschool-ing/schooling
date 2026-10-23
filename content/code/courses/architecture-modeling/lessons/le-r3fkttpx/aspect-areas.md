---
title: Four aspect areas, and the two that cut across them
version: 1
---

**IAF's aspect areas divide the enterprise into the parts an architecture describes: business,
information, information systems and technology infrastructure.** They look like TOGAF's four
domains from lesson 8, and they mostly are, with one difference worth noticing.

| aspect area | what it covers | Carcará's digital boarding |
| --- | --- | --- |
| **business** | goals, services, processes, organisation, people | the counter sale with a QR receipt; the agents' new role |
| **information** | the information the business needs, its meaning and ownership, independent of systems | what a *ticket* is; who owns a passenger's contact details |
| **information systems** | the applications that store and process the information | ticketing, the boarding app, the counter mode |
| **technology infrastructure** | the platforms, devices and networks the systems run on | the cloud region, drivers' phones, station tablets and links |

## Information comes before systems

The difference from TOGAF is that **IAF keeps information as an area of its own**, above the systems
that hold it. TOGAF's data architecture sits with applications in phase C; IAF asks about information
as the business understands it first, and only then about where it is stored.

At Carcará the separation found a real problem. In the information area, the question *what is a
ticket?* had two answers: for Sales, a seat on a trip, paid for; for Finance, a revenue line, which
might cover several seats bought together. Neither was wrong, and both had been built into systems
without anybody noticing they disagreed. That is a bounded-context boundary from lesson 4's map,
found by an enterprise framework from the other direction.

## Security and governance across everything

IAF's two cross-cutting areas apply to every cell of the grid rather than sitting in one column:

- **security**: at the contextual level, *why do we protect this?* (the LGPD, fraud at the door); at
  the conceptual level, *what must be protected?* (a passenger's document number, the validity of a
  ticket); at the logical level, *how?* (signed ticket lists, access per role); at the physical level,
  *with what?* (the key management service, the phone's secure storage);
- **governance**: who decides, at each level, and how a decision is checked, which is lesson 8's
  boards and dispensations again.

Drawn as bands across the grid, they make a point that a separate security chapter at the end of an
architecture document does not: **security is decided at every level, and a decision made only at
the physical level, a product bought, is a decision missing its reasons**.

## Filling one row, not the whole grid

Sixteen cells times two cross-cutting concerns is a lot of architecture, and IAF does not ask for all
of it. A typical piece of work fills **the cells the change touches, to the depth the decision
needs**. Carcará's programme filled all four levels of information systems and technology, the top
two levels of business and information, and left the rest as references to what already existed.
