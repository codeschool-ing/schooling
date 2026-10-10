---
title: Writing one: the seat-hold record
version: 1
---

The most expensive decision in Coreto's strategy is the third action from lesson 1: the new
Reservations team spends two quarters removing the row locks from the seat-hold path. In April, with
the on-sale load test running and a design agreed, Mateus Araújo and the Reservations team wrote it
down. This is the record as it was merged into `coreto-core`, and the rest of this section takes it
apart.

> **ADR-0006: Hold seats without row locks**
>
> **Status:** Accepted, April. Supersedes ADR-0002.
>
> **Context**
>
> A seat hold keeps a seat for a buyer while they pay. The reservation module takes a hold by
> locking the seat's row inside a database transaction and keeps the lock until payment succeeds or
> the buyer leaves (ADR-0002). In an ordinary hour nobody notices. In a big on-sale, many buyers want
> the same seats in the same minute: the locks queue, checkout requests time out, and buyers watch
> seats vanish and come back. Coreto runs about twelve big on-sales a year, and the incident log
> traces their failures to this path.
>
> The hold path also costs time every sprint. Changes that touch it take about 31 engineer-hours a
> sprint more than they would on clean code, by the time logs kept since February.
>
> We considered three approaches. Keeping the locks and shortening the transaction is the cheapest,
> and the on-sale load test (ADR-0004) still shows the queue forming at on-sale traffic. Moving the
> reservation module into a service of its own is the microservices migration the strategy has put
> off for a year, and it would not remove the lock by itself. Taking holds without locks changes the
> data model and every report that counts held seats.
>
> **Decision**
>
> We will record each hold as a row of its own with an expiry time, and take it with a single insert
> that the database refuses when a live hold for that seat already exists. Nothing waits on a lock.
> Reads ignore expired holds, and a sweeper job removes them.
>
> We will move venues to the new path one at a time behind a flag, and no change to the hold path
> merges without a load-test run attached to the pull request.
>
> **Consequences**
>
> - A buyer who loses a seat to someone else is told at once instead of waiting for a timeout.
> - The length of a hold becomes an explicit setting. Choosing it is a product decision; Júlia
>   Sato's team owns it, and this record does not set it.
> - The sweeper job is now part of the on-sale path and needs its own alert.
> - The Data team's reports of held seats read a different table and have to change.
> - The Reservations team's first two quarters go to this; nothing else on its list starts first.
> - While the flag exists the change can be rolled back. Once the old path is deleted, going back
>   means a new record.

It fits on one page, and every line in it could be checked by somebody who was not in the room.

## The title names the decision

"Hold seats without row locks" is a decision. **"Seat-hold performance" would be a topic**, and a
log of topics tells a reader where to look and nothing about what was chosen. Nygard asked for a
short noun phrase, and the useful version of that is the decision itself, short enough to scan in a
long list. The number in front is the record's identity; the title can be improved later, and
the number never changes.

## The context is fair to the options that lost

The commonest fault in a first ADR is a context written after the decision and arguing for it. The
test is whether an engineer who preferred another option would read the context and call it fair.
ADR-0006 passes because it gives each rejected approach its real advantage: the transaction fix is
the cheapest, and the record says so before saying why it was not enough.

**The context is also where the facts of the moment go.** "The strategy has put off microservices
for a year" will not be true forever. When it stops being true, a reader can see that one reason
behind this decision has gone and can ask whether the decision still holds. Without that sentence,
the choice looks like a judgement against microservices, which it never was.

## The decision says "we will"

Full sentences in the active voice. "We will record each hold as a row of its own" can be checked in
review: a pull request either does that or does not. "Holds should ideally avoid locking" cannot,
and it leaves room for the next engineer to read it as optional.

A decision can carry how it is rolled out when the rollout is part of what was decided. Here it is:
venue by venue behind a flag, with a load-test run on every change. Leave out the schedule, the
names of the engineers and the ticket numbers. They belong to the plan, and the plan changes weekly.

## Consequences include the bad ones

A consequences list with only benefits reads like a sales pitch, and reviewers stop trusting it.
ADR-0006 lists a new job that can fail, a set of reports that break, and two quarters of a team.
**Those lines are why the record is believed.**

The most valuable line is the second one. It says that the hold length is now a product decision and
names who owns it. Lesson 16 showed how a technical change can hand product a choice it never knew
it had; this record hands it over in writing, on the day the choice appears.

## Writing your own

Open the plain-text editor you set up in lesson 1. Make a folder called `adr` beside the one-page
strategy you wrote in lesson 3, and in it a file named `0001-record-architecture-decisions.md`. That
first record states the practice itself: that this team records its architecturally significant
decisions, in this format, in this place.

Then write a second one, for a real decision your team took in the past year that somebody has
already asked "why" about. Use the five parts in order. Two checks before you call it finished:

1. Give it to a colleague who was not part of the decision. They should be able to say which
   options were rejected and the reason for each, without asking you.
2. Read the consequences aloud. If none of them is a cost, you have left something out.

Expect the context to take longer than the decision. That is the part nobody can write later.
