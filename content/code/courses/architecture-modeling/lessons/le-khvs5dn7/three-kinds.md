---
title: Three kinds of requirement, and the one architecture hears most
version: 1
---

**A requirement is anything the system must do or be, and there are three kinds: functional
requirements, quality attributes and constraints.** `architecture-role` lesson 7 separated them and
showed how to ask the business for each one. This lesson is about writing them down as models: in a
form precise enough to be checked, ranked and traced to the decisions that meet them.

| kind | what it says | a Carcará example |
| --- | --- | --- |
| **functional** | what the system does | *a passenger can cancel a paid ticket up to three hours before departure and get a full refund* |
| **quality attribute** | how well it does it | *the driver can check a ticket in under a second with no signal* |
| **constraint** | a decision already made by somebody else | *personal data stays in Brazil (LGPD and the company's policy)*; *Frota cannot be modified* |

The older name for quality attributes is **non-functional requirements**. It is still in job
descriptions and tender documents, and it is a poor name: availability and security are very much
about function, and calling them *non-functional* makes them sound optional. This course uses
*quality attributes*, and the lesson's title keeps both so you recognise either.

## Why architecture hears the qualities

Functional requirements decide **what the system contains**. Quality attributes decide **how it is
built**, and that is the architect's work. Take one feature, *check a ticket at the door*, and two
quality requirements for it:

- *the check works with no signal*: the ticket list has to live on the phone, which means a sync
  process, a published format and a rule for tickets sold after the last sync (lesson 4's map);
- *a cancelled ticket is refused at the door within one minute of cancellation*: the phone has to
  hear about cancellations almost immediately, which needs signal.

Both are reasonable, and **they pull against each other**. No amount of work on the feature resolves
that; it is a decision about qualities, and Celeste has to make it with the costs in front of her.
The rest of this lesson builds the tools that put those costs in front of her: a catalogue so no
quality is forgotten, scenarios so each one can be checked, and a tree to rank them.

## Architecturally significant requirements

Not every requirement shapes the architecture. *The ticket e-mail shows the bus company's logo*
changes a template. A requirement is **architecturally significant** when meeting it, or changing it
later, would change the structure: where data lives, what talks to what, what runs where. Carcará has
a few hundred requirements and about fifteen significant ones. Finding those fifteen early is the
point of everything that follows.
