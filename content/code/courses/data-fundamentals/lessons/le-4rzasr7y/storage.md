---
title: Storage: three zones, and the one nobody edits
version: 1
---

**A pipeline keeps the same data more than once, on purpose: as it arrived, as it was cleaned, and
as somebody will read it.** It is tempting to picture storage as the end of the line, one database
where the data finally comes to rest. In practice each stage writes its result somewhere and the next
stage reads it from there, and the copies have different jobs.

## The three zones

| zone | what it holds | who reads it | also called |
|---|---|---|---|
| **raw** | the data exactly as ingestion copied it, one directory per day | the transformation, and nobody else | landing, bronze |
| **cleaned** | the same rows with the rules applied: bad rows dropped, types fixed, names joined in | the data team, and the next transformation | staging, silver |
| **curated** | tables shaped for one use: rides per station per day, a feature table for a model | analysts, reports, dashboards, models | marts, gold |

**Bronze, silver and gold** are the names Databricks made popular for the same three, and you will
hear them in teams that have never used Databricks. The names differ from company to company; the
three jobs do not. In the program you will build, they are three directories: `raw/`, `clean/` and
`curated/`.

## Raw is kept, and nobody edits it

**The raw zone is the one copy of what the source actually said, and it is the only zone that cannot
be rebuilt.** Everything else can: cleaned and curated are the output of programs, and a program can
be run again. Raw is the output of a moment that has passed. The previous section showed why: the
source keeps the present, the sensors keep two days, and the app updates a refunded ride in place.

That one property pays for itself the first time a rule changes. Suppose Marta decides that a false
start is a ride under one minute, not under two. With raw kept, the fix is to change one number in
the transformation and run it again over every day since the beginning; the cleaned and curated
zones come out as though the rule had always been one minute. Without raw, the rides between one and
two minutes were dropped months ago and nothing can bring them back.

So the rules for raw are short:

- **nothing writes to it except ingestion**;
- **a row in it is never edited**. A day is added, or a whole day is replaced by copying it again
  from the source; a single row is never patched by hand;
- **it is kept as long as somebody may need to rebuild from it**, and not longer. Raw is also where
  personal data arrives untouched, so how long it is kept is a decision about privacy as well as
  cost. Lesson 7 comes back to it.

## One directory per day

The path `raw/date=2025-09-15/` does a job of its own. Splitting a table into directories by the
value of one column is called **partitioning**, and the `name=value` spelling of the directory is a
convention many tools read: given a question about Monday, they open Monday's directory and skip the
rest. It also makes the unit of work obvious. Replacing Monday means replacing one directory, which
is how section 09 repairs a pipeline that counted Monday twice.

Lesson 9 uses the same word for something larger, splitting data across machines; the idea is the
same, one key deciding where each row goes.

## Where the zones live

On your machine, the zones are directories. At a company they are usually **object storage** in a
cloud — files addressed by a path, cheap to keep and slow to change, which is the `cloud` course's
subject — or tables in a **warehouse**, which `warehouse-modeling` builds. The format of the files
matters as much as the place, and lesson 6 compares five of them. None of that changes the three
jobs, or the rule that raw is kept as it arrived.
