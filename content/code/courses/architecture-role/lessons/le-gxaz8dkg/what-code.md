---
title: Which code, and which code not
version: 1
---

The obvious way for an architect to keep coding is to take a story from the team's board, and it is
the one most likely to go wrong. **An architect writes code that nobody's delivery waits for**, and
there is plenty of it: spikes, prototypes, walking skeletons, fitness functions, tooling, small
fixes and pairing. This section explains the rule and then goes through the list.

## The rule: off the critical path

A team's **critical path** is the chain of work that decides when something ships: the pieces where
a delay in one is a delay in the release. Whoever holds a piece of it has to be available to finish
it.

An architect's calendar is built for something else. Renata's week, once the reviews, the forum, the
conversations with Helena and Sílvio and the questions from five teams are in it, leaves about **two
uninterrupted half-days**. Suppose she takes a story the team estimates at three days of focused
work, which is six half-days. At two half-days a week, it takes her **three weeks** of elapsed time.
If the release waits for that story, the release waits three weeks for three days of work, and the
team cannot even help without first understanding how far she got.

So the rule is about the shape of the work, not about its importance or its difficulty. **Code an
architect writes should be finishable in the gaps of an interrupted week, and nobody should be
blocked when it is late.** Lesson 16 comes back to the critical path from the other side, as one of
the places where the role ends. Here it decides what to pick up.

The tempting exception is the hardest, most interesting piece of a project: the one where the
architect's experience seems to matter most. It is also the piece most likely to be on the critical
path, and taking it means the team learns least exactly where there is most to learn. The
alternative is to **pair on it** with whoever owns it: the experience gets used, the owner stays the
owner, and nobody waits on the architect's calendar.

```schooling-figure
@@FIG:map@@
```

The figure places the usual candidates on two axes: how much the work teaches about the design, and
how much the team's delivery waits on it. The good region is the bottom right. What follows is the
list, roughly from the most to the least common.

## Spikes and prototypes

A **spike** answers a question with a few days of code and throws the code away, as lesson 14 did
when Ícaro and a Tracking engineer found out what Tracking records at delivery. An architect is
well placed to write spikes because the questions are often theirs: will this library handle our
volume, does this database's replication behave the way the documentation says, how much of the
monolith does this module drag in when we try to extract it.

A **prototype** is a spike that something is built on: a rough version that a person can use, to
learn whether the idea works before the real one is built. Its danger is well known — a prototype
that works is tempting to ship. The defence is to say what it is in the code itself, in the
repository's name and the first line of the README, and to agree before writing it what happens to
it afterwards.

## The walking skeleton

Alistair Cockburn named the **walking skeleton**: a tiny implementation of the system that performs
one small function from end to end, linking the main architectural parts together. It does almost
nothing, but it does it through every layer: the button, the API, the database, the call to the
outside world, the deploy pipeline.

When Helena and Sílvio chose to start instant payout with a provider, Renata wrote the skeleton in
her two half-days a week, over a fortnight, before the team started on the real pieces.

```schooling-figure
@@FIG:skeleton@@
```

**The skeleton is architecture made executable.** Every connection in the design is exercised once,
so the problems that live in connections — authentication between services, a firewall rule, a
message format two teams read differently — show up in the first fortnight instead of the last. It
also gives the team a running system to add flesh to, which turns "integrate everything at the end"
into a sequence of small changes to something that already works.

It suits an architect for the reasons of the last section. Nobody waits for it, because nobody can
start the pieces until the design is settled anyway. And writing it is the fastest calibration
there is: Renata found in the first afternoon that the provider's sandbox needed an allow-listed IP
address, which meant a change in Platform's network configuration and a ticket for Paula's team. In
the real project, that would have been a surprise in week nine.

## Fitness functions and tooling

Lesson 9 built a **fitness function**: a short program that fails the build when the code breaks
an architectural rule, such as one module importing another's internals. Fitness functions are
architecture expressed as tests, and the architect is often the right author, because the rule is
theirs and writing it forces them to state it precisely. The same goes for **tooling** around the
architecture: a script that draws the current dependencies from the code, a check that every service
has an owner in the catalogue, a template that starts a new service on the paved road of lesson 9.

These are some of the most useful things an architect can write. They keep working when the
architect is in a meeting, they turn a standard from a document into a check, and they are off every
critical path by construction.

## Small fixes and pairing

A **small fix** is a bug from the backlog, a slow query, a confusing error message: something real,
in the production code, that no release is waiting for. Small fixes keep an architect's hands on the
code the team writes every day, with its tests, its review and its deploy, which is where the
calibration of the first section comes from. Renata takes one every week or two, picked with the
team's tech lead so it is something they agree is worth doing.

**Pairing** is the most effective of all, and it is not about the architect's own code. Sitting with
an engineer on the real work — the engineer driving, the architect navigating — gives the architect
the full feel of the system and gives the engineer the architect's reasoning, at the moment it
applies. Renata's afternoon with Ícaro in the previous section was pairing; it calibrated her and,
from the questions she asked aloud, taught him how she thinks about transactions. The craft of doing
it well is the subject of `architect-communication` lesson 12.

## Reading code, and reviews

Reading counts too. An architect who reads a few pull requests a week, in the parts of the system
where the important decisions live, sees how the design is turning out in practice. The point is to
read, not to approve: an architect who has to approve every pull request has made themselves the
critical path by another route, and lesson 16 puts that outside the role. Comments are welcome; a
gate is not. How to turn a review into teaching is `architect-communication` lesson 11.

What reading cannot give is the friction. A pull request shows the change and hides the 41 minutes
spent waiting for the tests. That is why reading complements writing rather than replacing it.
