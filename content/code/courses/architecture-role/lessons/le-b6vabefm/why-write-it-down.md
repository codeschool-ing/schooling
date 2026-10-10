---
title: Why the decision has to be written down
version: 1
---

The objection comes in two forms. "The code is the documentation", from engineers who have seen
too many wikis rot; and "we all know why we did it", from teams small enough that this is still
true. **Both describe the present, and a decision record is written for the future**: for a reader
who is not in the room, may not have joined the company yet, and will be about to change something
they do not understand. Three readers in particular, and one more benefit that is the architect's
own.

## The future reader, who is about to fix something

Eighteen months after record 7, a new engineer on Payments finds a nightly job that asks Tracking's
API for proved deliveries. Every payout already arrives by event. The job has not found anything
in weeks. It looks like a leftover from a migration, and deleting it is a satisfying afternoon's
work.

Without the record, the job goes. With it, the engineer reads one consequence: *the nightly check
is the only way we will notice an event that was lost.* The job finds nothing in weeks because
events are rarely lost, and the one night it finds something is a driver who would otherwise not
have been paid. **The code shows what the job does; only the record says what would go wrong
without it.**

Chesterton's fence is the old name for this: do not remove a fence until you know why it was put
up. A decision record is the note nailed to the fence. It costs one sentence in the consequences,
written by the person who knew.

## The meeting that happens again

Every company has a decision that is argued about every quarter. At Carreto, before the log, it
was polling. Somebody new would ask in the architecture forum why Payments did not simply ask
Tracking for new proofs every few minutes, the people who remembered the last discussion would
reconstruct it, partly and differently, and an hour later the meeting ended where the previous
one had.

With a record, the conversation is shorter and better. Kátia Lemos raised polling again for a
different integration, and Renata pointed at record 7. **The question became: what in this context
has changed?** If nothing, the decision stands, and the hour is saved. If something has (Tracking's
API is now cheap to call, say, or the slack in the budget has grown), then re-opening the decision
is legitimate, and the way to do it is a new record that supersedes the old one, with the new
context written down.

That is the difference between revisiting a decision and re-litigating it. **Revisiting starts
from what changed; re-litigating starts from scratch**, and only the first is possible when the
first decision was written down.

The arithmetic is easy to do for your own team. A forum of eight people spending an hour on a
question already settled costs eight engineer-hours. Twice a year for three years, that is 48
hours, against the two or three hours it took to write the record and have it reviewed.

## The person who joins next month

A new engineer learns a codebase by reading it, and the code answers *what* fluently and *why*
never. **A decision log is the shortest history of a system there is**: a numbered list of the
choices that shaped it, each with the forces of its moment. Reading Carreto's log from the first
record takes about an hour, and at the end a new engineer knows why the monolith still owns the
load module, why Tracking has its own database and why payouts are driven by an event, which used
to take months of asking.

It also changes what a new person dares to do. Somebody who knows why a structure exists can
propose changing it with a real argument. Somebody who does not either leaves everything alone or
changes things that had reasons, and neither helps.

## The person who decided

The fourth reader is the one this lesson's title points at. Lesson 3 made the architect
accountable for the structural choices: answering for them when they go wrong. **A record is what
lets a decision be judged by what was known when it was taken, rather than by what happened
afterwards.**

Decisions are made under uncertainty, and some good decisions turn out badly. If record 7's event
approach one day causes an incident because the broker loses messages in a way nobody foresaw,
the record shows that the team knew events could be lost, built the nightly check for exactly that
case, and wrote it down. The review after the incident can then ask the useful question, which is
whether the check worked, instead of the useless one, which is who chose events. Without the
record, hindsight writes the history, and hindsight always knew.

## What not to write down

A log that records everything is read by nobody. **The test is the one from the first section of
this lesson: one-way doors, and decisions that reach beyond one team.** Pricing's logging library
does not need a record; Tracking's position store does, because it is expensive to reverse even
though it stays inside one team; record 7 does, on both counts.

Two habits kill a log faster than missing records:

- **Writing records after the code has merged**, as paperwork. Their contexts then argue for what
  was already built, the rejected options are invented to look fair, and readers learn that the log
  is decoration.
- **Letting records grow into design documents.** A proposal is the right place for a long
  argument, and `architect-communication` lesson 2 covers how to write one. The record is the page
  that remains after the argument ends: what was decided, why, and what it costs.

## Where the records live

Carreto keeps each record in the repository of the system it changes most, in a `docs/adr/`
directory, one Markdown file per record, reviewed in pull requests like code. A decision that
spans the whole company goes in one agreed repository, and Renata keeps a short index there that
lists every record across the repositories, so the log can be read in one place.

**The architect's responsibility is the log as a whole**: that the significant decisions are in
it, that they are reviewed by the people they affect, that superseded records point at their
successors, and that a new engineer can find it in their first week. Lesson 8 takes up the wider
question of keeping documentation alive, of which the decision log is the part that ages best,
because nobody is expected to keep it current.
