---
title: Where exactly-once stops
version: 1
---

**Kafka's exactly-once covers what Kafka writes: records in topics and offsets in
`__consumer_offsets`. Anything else a program does in between is outside the transaction, and an
aborted transaction does not take it back.** That boundary is narrow and it is precise, and most
of the disappointment people have with "exactly once" comes from expecting it somewhere else.

Take `eos_copy.py` from the last section and give it one more line: for each big sale, besides
copying it, send the shop manager an email. Crash it as before, after 25 sales. The copies of the
unfinished batch are aborted and written again on the restart; the emails for that batch were
already sent, and they are sent again. The manager receives two emails for some sales and one for
the rest, from a program that is exactly-once by every measure Kafka has.

The same happens with every effect that is not a Kafka write:

| what the program does | why the transaction does not cover it |
|---|---|
| inserts a row in PostgreSQL | the database has its own transaction, which commits on its own |
| calls a payment API | the payment happened, whatever Kafka decides afterwards |
| writes a file | the file is on disk before the commit and stays after an abort |
| sends an email or a push message | nobody can unsend it |

A two-phase commit across Kafka and a database would close the gap in theory, and Kafka does not
offer one: a coordinator that holds locks in two systems while it waits for both is slow, and when
it fails it leaves both stuck. What production systems do instead is make the second system
**tolerant of seeing the same thing twice**, which is a property of the receiving side and costs
much less than a transaction.

## What the receiving side can do

There are three answers, and lesson 8 builds each of them against SQLite:

- **write in a way that repeats harmlessly**: setting a value rather than adding to it, keyed by
  the event, so the second write changes nothing;
- **remember what has been done**: keep the ids of the events already applied, in the same
  database transaction as their effect, and skip an id that is already there;
- **keep the offset with the data**: store the position in the stream in the same transaction as
  the effect, and start from it, so the database and the stream cannot disagree.

All three turn **at-least-once delivery into exactly-once effect**. That phrase is the honest
version of the promise: the messages may arrive more than once, and the result is as if each had
arrived once. It is what "exactly once" means outside a single system, and the lessons that follow
use it in that sense.

For the email there is no such property, and the usual answer is a table of emails already sent,
keyed by the event that caused them, checked before sending. It narrows the window to the moment
between sending and writing the row, and does not close it. Some effects can only be made rare.
