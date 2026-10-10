---
title: When not to
version: 1
---

**Most of a typical system does not need CQRS, and applying it everywhere is one of the commonest
ways to make a simple application expensive.** Its own advocates say so: Greg Young and Martin
Fowler both describe it as a pattern for particular parts of a system, the bounded areas where reads
and writes genuinely pull apart, and warn against it as an architecture for the whole. The cost is
easy to see in this lesson's own files.

```
ana@laptop:~/patterns/cqrs$ wc -l strained.py commands.py read_model.py
  64 strained.py
 110 commands.py
  73 read_model.py
 247 total
```

The strained class did the same job in 64 lines. The split version takes 183 for the write model and
two read models, before any of the outbox machinery of the last section. Part of the difference is
the demonstration code at the bottom of each file, and most of it is real: six event and command
classes, a dispatch table, two projectors and the schema of a table. Every one of those is something
a reader has to find, and every new screen now means an event review as well as a query.

## The costs, named

**More code and more concepts.** A screen that showed a field straight from the model now needs the
field in an event, a projector that copies it, and a column in a read model. Three places to change
for one label.

**Eventual consistency, if the projection is asynchronous.** The previous section's window has to be
designed for on every screen that follows an action, and explained to people who did not choose it.

**Two models to keep in step.** A bug in a projector produces a read model that disagrees with the
write model, quietly. Rebuilding fixes it, provided somebody notices and the rebuild is fast enough
to run; at a few million events, that is an operation with a runbook.

**Harder onboarding.** A new developer looking for "where is a loan saved" finds a handler, an event
class and two projectors, and has to learn the flow before changing anything.

## The cases that do not need it

**A screen that edits a record and shows the same record.** A member's profile page reads the
fields it writes. The write model and the read model would be the same shape, so a split doubles
the code and buys nothing. Most administrative screens, the CRUD part of any system, are this case.

**Rules that are trivial.** If the only rule is "the title must not be empty", there is nothing for
a small write model to protect, and the strained class is not strained.

**Reads that are cheap enough already.** If the availability query takes two milliseconds on the
real data, the strain of the first section is a design smell and not yet a problem. An index or a
database view, level 1 of the three levels, may be all it ever needs.

## The cases that do

The signs are the ones the first section listed, measured rather than imagined: queries walking
structures built for writes and getting slower with the data; screens forcing fields into the rules'
model; read traffic that is many times the write traffic and would scale separately; or several
screens that each need the same facts in a different shape, like `Availability` and `MemberLoans`.
When those appear in one part of the system, split that part. The loan desk might qualify, and the
member's profile page beside it still would not.

`architecture` lesson 13 makes the same argument from the system's side, where the costs are
counted in services, message brokers and on-call hours; read it with this lesson's code in mind. And
the next lesson takes the events of this one a step further: if the write model publishes every
change as an event anyway, it can keep the events themselves as its state.
