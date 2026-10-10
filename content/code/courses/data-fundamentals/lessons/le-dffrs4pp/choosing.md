---
title: When a stream earns its cost
version: 1
---

**Batch is the default, and a stream has to earn its place by an answer that loses its value within
minutes.** "Can we have it in real time?" is one of the most common requests a data team hears, and
"real time" there usually means "fresher than it is now". Fresher than now is often a batch job that
runs every hour instead of every night.

The test is what somebody *does* with the answer, and how soon:

| question at Roda Livre | what is done with it | how fresh | shape |
|---|---|---|---|
| which stations will be empty in the next half hour | a van moves bicycles before the station empties | minutes | stream |
| has this card been used at four stations in ten minutes | the ride is blocked while it can still be blocked | seconds | stream |
| rides per station last week | Marta plans the van routes for next week | a day | batch |
| revenue per month | the finance report | days | batch |
| rides so far today, on the office screen | people look at it | an hour is fine | batch, run hourly |

The last row is the one to watch. A number on a screen that is looked at and acted on by nobody wants to
be live and rarely needs to be. A stream built for it costs everything this lesson showed. There is a
process that never stops and has to be watched at night, a watermark somebody has to choose and a
decision about late data. There is state that has to survive a crash, and duplicates to make harmless. A
batch job run hourly pays none of those, and its numbers can be checked against the source the way lesson 7 did.

## Between the two

Two middle paths are worth recognising by name:

- a **micro-batch** runs a small batch job every few seconds or minutes over what arrived since the last
  run. Spark Structured Streaming works this way by default, and it is how many teams get a stream's
  freshness with a batch job's simplicity;
- **change data capture**, from lesson 4, turns a database into a stream of its changes, which is often
  the first stream a company has, and is read by a consumer exactly like the one in this lesson.

## Four questions before building a stream

1. What decision does the answer feed, and how long can that decision wait?
2. What should happen to an event that arrives late, and how late can events be? Lesson 4's questions to
   a source's owner apply here, with the outages of this lesson in mind.
3. What happens if an event is processed twice? If the answer is "a number is wrong", the writes must be
   idempotent before anything else is built.
4. Who is woken up when it stops, and is the answer worth that?

If the first answer is "a day", the other three need no answer. The rest of the `data` track builds
batch pipelines for that reason. `streaming`, in the Data Platform track, is the course for the cases
where the first answer is a number of seconds.
