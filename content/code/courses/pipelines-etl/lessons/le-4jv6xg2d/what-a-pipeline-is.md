---
title: What makes a script a pipeline
version: 1
---

**A pipeline is not defined by what it does but by how often it does it.** The SQL Ana ran in
`warehouse-modeling` to build the warehouse moved data from a source to a destination and
transformed it on the way. It was not a pipeline. It ran once, while she watched, and if it had
failed halfway she would have seen it, fixed it, and run it again.

A pipeline is the same work with nobody watching, and that one change forces four properties
the one-off script never needed:

- **It runs again on its own.** Every night, every hour, or every time a file lands. Whatever
  started it, a person did not.
- **It knows what it already did.** Tonight's run must not copy yesterday's orders a second time,
  and it must not skip the ones that arrived during last night's run. Lesson 4 calls that the
  watermark.
- **It can be run twice and give the same answer.** A run fails at 3 a.m., somebody reruns it at
  9, and the warehouse must not now hold the night twice. That property has a name, idempotency,
  and lesson 15 is about nothing else.
- **It says when it fails, and where.** A job that dies silently is worse than one that never ran,
  because the dashboard keeps showing yesterday's numbers as if they were today's.

## Source, steps, destination

Every pipeline in this course has the same three parts:

1. **A source**, which somebody else owns and which changes without asking: the shop's database,
   an API, a file a supplier drops, a stream of events.
2. **Steps** that extract, transform and load, and lesson 2 is about the order those come in.
3. **A destination** that people read, here the warehouse `wh`. Its readers trust that what they see
   is complete and current, and they cannot check either.

**The destination is the half people forget to design for.** A pipeline that writes a row at a
time leaves its readers looking at half a day while it works. One that writes into a separate
table and swaps it in at the end never does. The difference is invisible until the morning a
manager opens a report at the wrong minute.

## Who owns what

The source belongs to the team that runs the tills. The warehouse belongs to whoever reads it. **The
pipeline belongs to the person who gets the phone call**, and in a team of two that is the person
who wrote it. Everything this course asks you to add — a check, a retry, a log line — is something
that person will be glad of at 3 a.m. Lesson 10 is that night.
