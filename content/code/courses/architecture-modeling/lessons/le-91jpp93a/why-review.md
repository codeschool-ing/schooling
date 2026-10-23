---
title: What an architecture review is for
version: 1
---

**An architecture review checks a design against the qualities it has to have, to find risks while
they are still cheap to deal with.** It is not a code review at a larger scale, and it is not an
approval gate, although organisations often turn it into one. `architecture-role` lesson 11 showed
how to review one design document; this lesson is about evaluating a whole architecture, or a large
change to one, as a deliberate exercise.

## When a review pays

A review costs the time of several senior people, so it has to be placed where it buys most:

- **before a commitment that is hard to reverse**: before the digital boarding programme of lesson 8
  chose its target, before a database is picked, before a contract with a supplier;
- **before a known stress**: the São João peak, a migration, a launch in a new region;
- **after a long drift**: a system that has changed one pull request at a time for a year no longer
  matches anybody's picture of it, and the review is also how the picture gets redrawn.

Carcará's first review came from the second kind. Three weeks before São João, Celeste asked whether
the platform would hold, and nobody could answer from memory.

## What it is checked against

A review needs something to check the design against, and that something is lesson 6's work: **the
quality scenarios and the utility tree**. Without them a review turns into a conversation about
taste, *I would have used Kafka*, which nobody can settle. With them, every comment can be put as a
question about a scenario: *does the design meet QS-01, 2,000 purchases a minute, and how do you
know?*

If a team asks for a review and has no scenarios, the first hour of the review is writing them.
That alone is often worth the meeting.

## What it produces

The output of a review is **a short list of risks, each tied to a scenario, ranked, with an owner
and a next step**, not a verdict. *Approved* and *rejected* are decisions somebody else makes with
the list in hand. A review that ends in *looks good* without a list has not been done; one that ends
in forty undifferentiated comments has been done badly. The rest of this lesson is about getting
from scenarios to that list.
