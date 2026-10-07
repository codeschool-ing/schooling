---
title: Only as long as it is needed
version: 1
---

Every law in this course says the same thing about time. The LGPD ends processing when its purpose is
met or its period ends (article 15) and lists the few reasons to keep data after that (article 16,
lesson 7). The GDPR calls it **storage limitation**: data kept in a form that identifies people **no
longer than necessary** for the purposes it was processed for (article 5(1)(e)). Neither law gives a
number. Each says the controller must have one, and a reason for it.

Lesson 7's facts query found what happens without one: **29,352 prescriptions, the oldest from 2019**,
and nobody had decided how long any of them should stay. Nobody had decided they should stay forever,
either. That is the usual state of a database: not a decision to keep everything, but the absence of
a decision to delete anything.

## Why keeping costs something

It is tempting to treat old data as free — storage is cheap — and three things make it expensive:

- **every incident is bigger.** A leak of a database that holds seven years of prescriptions is a leak
  of seven years of prescriptions. Data that was deleted cannot be stolen;
- **every request is harder.** An access request returns more, an erasure has more to find, a RIPD has
  more to justify;
- **every year it is less true.** An address from 2019 is likelier to be wrong than one from last
  month, and a decision made on it is likelier to be unfair.

## Two numbers that pull against each other

Some laws require **keeping** data — tax records, health records, employment records. Data protection
requires **not keeping** it beyond its purpose. The two meet in a retention schedule: for each kind of
record, the minimum other laws demand, and no more than the purpose justifies. Where a law requires
five years, five years is both the floor and, usually, the ceiling.

The rest of the lesson builds that schedule as a table, a purge that obeys it, the exception that can
stop the purge, and the trail that shows it all happened.
