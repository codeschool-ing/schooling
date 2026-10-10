---
title: Calibration, or knowing what a design costs to build
version: 1
---

Two pictures of the architect and code are common, and both are wrong. In the first, the architect
has moved past code: their time is too valuable for it, and writing it would be a step backwards.
In the second, the architect is the best programmer in the building and takes the hardest features
personally. **The reason an architect keeps writing code is neither status nor heroics. It is
calibration**: staying in touch with what a design costs to build, so that the next design is
priced correctly.

## What calibration means

An instrument is calibrated when its readings match reality. An architect is a kind of instrument.
Every design they propose carries an implicit reading of how much work it is, how much it will hurt
to operate and how hard it will be to change. Those readings come from experience with the real
system, and **experience decays when it stops being renewed**. The code changes, the build changes,
the libraries change, and the team's habits change. Somebody who last opened the repository a year
ago is reading an instrument that drifted while they were not looking.

Drift does not feel like anything. Nobody notices their sense of "that's a two-week job" getting
less accurate. It shows up only when a design meets the people who build it, and by then it is
their time being spent on the error.

## Renata's afternoon

Six months into the role, Renata proposed a change to how Payments records a payout. Instead of
writing the ledger entry and calling the bank in the same request, Payments would write the entry
and a message in one transaction, and a separate worker would read the messages and call the bank.
It is a well-known pattern, the transactional outbox, one answer to the guaranteed-delivery problem
of `architecture` lesson 7, and she estimated it at two weeks.

Bruno's team said six. Renata assumed they were being careful, and offered to pair with Ícaro for
an afternoon on the first piece, to show how small it was.

The afternoon did not go as she expected:

- the monolith's test suite now took **41 minutes**, against the 12 she remembered, and it failed
  twice on a test unrelated to their change;
- the payments code had moved to a newer version of the web framework, whose transaction handling
  she had never used, so the "one transaction" took an hour of reading to get right;
- deploying the worker meant a new entry in Platform's deployment configuration, which needed a
  review from Paula's team, which met on Thursdays.

A change she would have called an hour's work in her last year as an engineer took most of the day
and did not reach production that week. **The team's six weeks were not caution. They were
calibrated, and hers was not.** She rewrote the estimate, and more usefully, she put the 41-minute
suite into the risk register of the next proposal, because it multiplies the cost of every change
anybody designs.

Nothing in her design was wrong. It was mispriced, and a mispriced design is wrong in a slower way:
it gets approved against a cost it will not meet, and the difference is paid by a team that did not
choose it.

## What the code tells you that a diagram does not

Lesson 2 described the slide that disagrees with the code. An architect who does not read or write
code has no way to notice the disagreement, because the slide is all they see. Three things are
visible only from inside the code:

- **The real dependencies.** The diagram shows Payments calling Tracking through an API. The code
  shows that Payments also reads one of Tracking's tables directly, added during an incident two
  years ago, which is why a schema change in Tracking broke payouts last spring.
- **The cost of the ordinary loop.** How long it takes to make a change, run the tests, get a review
  and deploy. A design that needs five coordinated deploys is cheap where a deploy takes ten minutes
  and expensive where it takes a day.
- **Where the team's attention goes.** The files everybody touches every week, the module nobody
  dares to change, the workaround with a comment saying "temporary" from 2019.

**None of these appear in a design review.** They appear when you try to change something, which is
why the instrument is kept calibrated by changing things.

## Fowler's two architects

Martin Fowler made the argument in a short column in *IEEE Software* in 2003, "Who Needs an
Architect?". He contrasted two species, with mock Latin names. *Architectus reloadus* is the person
who makes all the important decisions, on the grounds that the developers are not experienced enough
to make them. *Architectus oryzus* is the one who stays aware of what is happening in the project,
spots the important issues and deals with them before they become serious — and whose most important
activity, in Fowler's account, is mentoring the developers so they can handle more of it themselves.

The detail that matters for this lesson is how Fowler pictures the second kind at work: programming
with a developer in the morning, sitting in a requirements session in the afternoon. The collaboration
is the job, and the programming is part of how the collaboration stays honest. An architect who
decides everything from outside the code is *reloadus* by default, however collaborative they mean
to be, because they have nothing to collaborate with.

Gregor Hohpe's *The Software Architect Elevator* (2020) gives the same idea a building. The
architect rides the elevator between the penthouse, where strategy and budgets are discussed, and
the engine room, where the systems run. The value is in the ride: carrying what the engine room
knows up to the people deciding, and carrying the decisions down in a form the engine room can use.
**An architect who stops at the penthouse has nothing to carry up.**

## Calibration and authority

Lesson 3 separated formal authority, the title, from earned authority, the track record.
Calibration is a large part of the second kind. A team listens to a review comment from somebody who
has felt the 41-minute test suite differently from one sent by somebody who has not, and it is right
to: the first comment comes from a reading of the system, the second from a reading of a diagram.

The opposite is just as visible. Renata's original two-week estimate was not a secret. Every engineer
in Payments heard it, and if she had defended it instead of pairing, they would have quietly
discounted her next proposal too. **Being wrong in front of the team, and correcting it from the
code, cost her an afternoon and bought more credibility than the right estimate would have.**

None of this asks an architect to be the best programmer on any team, or to be current on every
library. It asks them to stay close enough to the work that their sense of its cost keeps matching
the team's. The next section is about which code does that without getting in anybody's way.
