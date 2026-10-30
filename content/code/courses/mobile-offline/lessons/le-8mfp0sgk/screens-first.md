---
title: Start from the screens, not from the server
version: 1
---

**A device's schema is designed from the questions its screens ask, and the server's schema is a
poor starting point for it.** The usual first move is to copy the tables the API returns, one local
table per endpoint, and then discover that every screen needs a join, a sum and a sort before it
can draw anything. The server was designed for every client and every report. The phone has a few
screens and one person, and it can afford to be shaped around them.

So the first step is a list, written before any `CREATE TABLE`: each screen, the question it asks,
and how often. For the planner it is short.

| screen | the question | how often |
|---|---|---|
| course list | each course's name, how many sessions it has, how many minutes they add up to | every launch |
| a course | its sessions in a week, in date order | every time it is opened |
| the week | every session in a week, and the minutes planned and done | every launch, and after each tick |
| add a session | does the course exist; write one row | a few times a day |

Two things fall out of the list straight away.

**Reads outnumber writes by a wide margin.** The course list is read every time the app opens; a
session is added a few times a day. A schema that makes the write cheap and the read expensive has
the trade the wrong way round for a phone, and the next section moves work from the read to the
write.

**The questions name the indexes.** "A course's sessions in a week" is lesson 3's
`(course, date)` index, and "every session in a week" is its `(date)` index. An index nobody's
screen needs is a cost with no reader, and the list is how you know which ones those are.

## What the list leaves out on purpose

The server knows things the planner never shows: who created a course, when it was last edited by
an administrator, which other people study it. None of that is a column here. **A column the
device does not read is a column it downloads, stores, migrates and backs up for nothing**, and a
column holding somebody else's data is a column lesson 20 will ask you to justify.

The same list also tells you what must be on the device for the app to work offline. If a screen
asks the question, the answer has to be in the local database before the network goes, because
lesson 7's rule is that the screen reads the database and never the network.
