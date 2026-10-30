---
title: What a CRDT promises, and what it does not
version: 1
---

**A CRDT is a data type whose copies can always be merged, in any order, into the same state.**
The letters stand for conflict-free replicated data type. Lessons 13 and 14 took ordinary data, a
row with fields, and asked what to do when two copies disagree. A CRDT starts from the other end:
it shapes the data so that every pair of concurrent changes has a merge written down in advance,
and there is never a question left to ask.

The promise rests on three properties of the merge, and each one answers a problem a sync layer
really has.

| property | what it says | the problem it removes |
|---|---|---|
| **commutative** | merging A into B gives what merging B into A gives | devices sync in whatever order they find a network |
| **associative** | merging A and B, then C, gives what A with B-and-C gives | updates may travel through other devices, in groups |
| **idempotent** | merging the same update twice changes nothing | the retries of lesson 9 deliver some updates more than once |

Together they give **strong eventual consistency**: any two copies that have received the same set
of updates are in the same state, whatever order the updates came in and however often. Nobody has
to coordinate, no server has to decide, and a device that was offline for a week converges the
moment it has caught up.

## The promise is convergence, not intent

The common belief is that a CRDT resolves conflicts the way the person would have wanted. It does
not, and it does not claim to. **It guarantees that every device ends up agreeing; it does not
guarantee that what they agree on is right.** Where two devices set the same value at the same
time, a CRDT still has to keep one of them, and it does so by a fixed rule, the same on every
device. That is lesson 13's last write wins with a better tie-break, not a reading of anybody's
mind.

What makes CRDTs worth a lesson is that for some kinds of data the merge they write down is
exactly what people mean:

- **a counter** where every addition counts, so +30 and +45 make +75;
- **a set** where an item added on one device and another removed on a second both take effect;
- **a list or a text** where two people inserting at the same place both keep their words, in an
  order every device agrees on.

The next section builds the first two by hand, in a few lines each, so the guarantee can be
checked rather than believed. The one after uses a library for the third, which nobody should write
by hand.
