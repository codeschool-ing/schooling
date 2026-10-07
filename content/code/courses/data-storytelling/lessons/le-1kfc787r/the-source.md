---
title: The source: who measured it, and how
version: 1
---

A number is the end of a process: somebody decided what to count, something recorded it, and a query
added it up. **Questioning the source means walking that process backwards** until you know what the number
actually measures, which is often not quite what its name says.

## Faro's "late"

Marina's whole analysis rests on one field: whether a first box was delivered after the promised date.
Walk it backwards:

- **What is "delivered"?** The carrier's driver scans the parcel when it is handed over. Is the scan made
  at the door, or later at the depot when the van returns? If drivers batch their scans at the end of the
  day, a box delivered at 10:00 and scanned at 19:00 still counts as the same day, which is fine; if they
  batch them the next morning, some on-time boxes become late in the data.
- **What is "the promised date"?** The date shown at checkout, computed in Faro's system. Diego's reports
  use the date in the carrier's system instead, which can differ by a day for orders placed in the evening.
- **What about a box left with a neighbour, or a failed first attempt?** Each carrier codes these
  differently, and a failed attempt may or may not count as "delivered".

None of these questions means the finding is wrong. **They mean the finding depends on definitions somebody
can check**, and checking them before the meeting is cheaper than being asked in it.

## How to check a source

- **Read the definition**, in writing, from whoever owns the system. Lesson 4's table of definitions came
  from this step.
- **Trace a handful of records by hand.** Pick twenty first orders at random and follow each one: the
  checkout record, the scan, the customer's own message if there is one. Twenty records will not prove a
  rate, and they will reveal a definition that does not mean what everyone assumed.
- **Compare with an independent source.** Faro's customer-service tickets record complaints about late
  first boxes. If the tickets rise and fall with the late share, the scan is measuring something real.

## Measurement validity

The general question has a name in research: **validity**, whether a measure measures what it claims to.
"Delivered after the promised date, by the driver's scan" is a valid measure of lateness if the scan is made
at the door and the date is the one the customer saw. Every step that loosens either link loosens the
measure, and **the analyst is the person best placed to know which steps those are**, because they wrote the
query.
