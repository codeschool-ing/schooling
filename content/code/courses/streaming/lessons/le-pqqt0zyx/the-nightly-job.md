---
title: The nightly job, and the question it cannot answer
version: 1
---

**A batch pipeline answers questions about a period that has ended.** Every night at two, a job
collects yesterday's sales from the five shops of Ponto Final, cleans them, loads them into the
warehouse and finishes. By eight in the morning the manager can see what sold yesterday, and the
numbers are complete, checked and final. Most of the data in most companies moves this way, and for
most questions it is the right way.

The batch has a clock, and the clock is the whole design. The period is closed before the job
starts: at two in the morning nobody is still selling yesterday, so the job can read **everything**,
in any order, as many times as it likes. If it fails, it runs again on the same input and produces
the same output. If a shop's file arrives late, the job waits for it. Completeness is cheap because
the job runs after the fact.

## The question the batch cannot answer

At half past ten on a Saturday the shop in Recife sells its last copy of a book that is being
talked about on the radio. The other four shops still have it, and the website still says *in
stock*. A customer in Recife orders it online at eleven, for collection at the Recife shop that
afternoon. Nobody will notice until the nightly job runs — and by then the customer has made the
trip.

Nothing in the batch is broken. It answers the question it was built for, *what sold yesterday*,
perfectly. The question that went unanswered was **what is happening now**, and a pipeline that
runs once a day cannot answer it at any price: run it every hour and the gap is an hour, every
minute and the gap is a minute, and each step makes the pipeline more expensive without changing
its shape.

## How small can a batch get

The usual first answer is to shrink the batch. It works further than it sounds, and it is worth
knowing where it stops:

| period | what it costs | where it stops |
|---|---|---|
| a day | one job, one window of work, easy to rerun | the question is about today |
| an hour | 24 jobs a day, each re-reading its sources | a late file now delays the next run |
| five minutes | 288 jobs; starting each one is a large share of its cost | jobs overlap when one runs long |
| one event | — | it is no longer a batch |

Somewhere along that table the batch stops being a schedule and becomes a program that never
finishes: it reads what arrives, handles it, and waits for more. **That program is a stream
processor**, and the rest of this course is about what it has to do differently because it never
gets to say *that was everything*.

The most common wrong picture of streaming is the one this table invites: that a stream is a batch
run very often, and that the hard part is speed. Speed is the easy part. The hard part is that the
period never closes, so the questions a batch answers for free — *have I seen everything?*, *what
if I run it again?*, *in what order did things happen?* — each need an answer of their own. The
next section names them.
