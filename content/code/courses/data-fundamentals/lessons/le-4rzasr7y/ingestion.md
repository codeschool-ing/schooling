---
title: Ingestion: copying it out without disturbing it
version: 1
---

**Ingestion is the copy from the system that made the data to the place where the data team keeps
it, and its first rule is to change nothing on the way.** No renaming, no filtering, no fixing. A
row that looks wrong is copied wrong, because the copy is the evidence of what the source said, and
deciding what is wrong is a later stage's job, done where it can be undone.

The second rule is to **leave the source as you found it**. The app's database exists to unlock
bicycles; a copy that slows it down at six in the evening has broken the thing that pays for
everything. The program in section 08 opens the app's database read-only, so
it could not change a row if it tried. Lesson 4 names the bigger tools for the same rule: a replica
to read from, and reading the database's own log of changes.

Every ingestion answers three questions, and each answer has a name.

## Who starts the copy: pull or push

| | how it works | at Roda Livre |
|---|---|---|
| **pull** | the data team's program goes and asks, on its own schedule | each night, a program reads the day's rides out of the app's database |
| **push** | the source sends the data when it has it, to an address the data team runs | the dock sensors send each reading as it happens; the payments provider calls an address when a charge succeeds |

**With pull, the data team decides when; with push, the source does**, and the data team has to be
listening when it arrives. A pulled source that is unreachable can be asked again in an hour. A
pushed reading that arrives while the receiver is down is gone unless the sender tries again.

## How much is copied: full or incremental

**A full load copies the whole table every time. An incremental load copies only what is new since
the last copy.** Roda Livre has both, for good reasons:

- the **stations** table has twelve rows and changes a few times a year. Copying all of it every
  night costs nothing and can never miss a change;
- the **rides** table grows by a couple of hundred rows a day and will hold millions. Copying all of
  it every night would copy the same old rides again and again, so the program copies **one day**:
  the rides that started on the date it is given.

Incremental is cheaper and has a catch that full does not. It has to know what "new" means, and a
row that changes after it was copied — a ride refunded on Wednesday that started on Monday — is not
new by date and is missed. Lesson 7 is about exactly that, and the overlap that catches it.

## How often: batch or stream

A copy that runs once a night over a closed day is a **batch**. A copy that handles each sensor
reading within seconds of its arrival is a **stream**. Marta's morning report needs yesterday, so a
nightly batch is enough; a map of which docks are empty right now would not be. Lesson 8 is about
the difference, and about what a stream costs.

## Landing it raw

**Where the copy lands is called the landing zone, or simply raw**, and it is written in a shape as
close to the source as the format allows. The program in this lesson writes each table as **JSON
Lines** — one JSON object per line, one line per row, with the same column names the app uses — into
a directory named after the day:

```
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
```

The day in the path is how a later stage finds Monday, and how a re-run replaces Monday without
touching Sunday. Why the raw copy is kept and never edited is the next section's subject.
