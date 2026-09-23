---
title: ACID, with the honest version of the C
version: 2
---

Four letters that get recited a great deal. Three of them are promises the database makes, and one
of them is a promise about you.

## A — atomicity

**All the statements in the transaction take effect, or none of them do.** That is the last
section, and it holds through a crash: a machine that loses power mid-transaction comes back with
the transaction undone, because the database wrote down what it was doing before it did it.

The mechanism has a name you will meet again in lessons 9 and 10 — the write-ahead log. Changes go
to the log first and the tables afterwards, so a recovery can finish or undo whatever was in
flight.

## C — consistency, which is the odd one

The usual phrasing is *"a transaction takes the database from one valid state to another"*. Read
that carefully and ask the question it is avoiding: **valid according to whom?**

According to the constraints you declared. Foreign keys, `NOT NULL`, `CHECK`, unique indexes — the
things lesson 3 was about. The database enforces those, in a transaction as everywhere else.

It does **not** know that an order's total should equal the sum of its lines, or that a booking
should not exceed a room's capacity, unless you wrote that down as a constraint. If the rule lives
only in application code, a transaction does not enforce it, and no isolation level will.

So the honest statement of C is:

> **The database keeps the promises you declared. It has no opinion about the promises you did
> not.**

Which is why this letter is the one that misleads people. A team saying *"the database is ACID, so
our data is consistent"* has usually written most of their rules in a service layer, where the
letter does not reach. Lesson 3's argument — that a constraint is the only rule that is actually
enforced — is the same argument arriving from a different direction.

## I — isolation

**How much of another transaction's unfinished work yours can see.** This is the one with a dial on
it, it has four settings, and the rest of this lesson is about them.

The strictest setting behaves as though transactions ran one after another with no overlap. It is
also the slowest and it can refuse your transaction outright, which is why it is not the default
anywhere. The defaults differ between engines, and that difference changes what your application
does.

## D — durability

**Once `COMMIT` returns, the change survives a crash.** The database writes the log entry to disk
and waits for the storage to say it is there before the commit returns to you.

Two honest qualifications, because this is the letter with the most folklore attached.

**It is only as good as what is under it.** A disk that lies about having flushed — some consumer
hardware, some virtual machines, a filesystem mounted with the wrong options — turns durability
into a hope. The database did its part and the acknowledgement was false.

**And it is about this machine.** If the primary commits and then catches fire, a replica that had
not received the change yet does not have it. That is not a violation of durability; it is
durability meaning what it says. Synchronous replication is how you widen it to more than one
machine, and it costs latency on every commit, which is a trade somebody has to choose
deliberately.

## Two databases are not one transaction

`BEGIN` covers one database. Write to a database and send a message to a queue, or write to two
databases, and there is no `COMMIT` that covers both:

```localised
BEGIN;
UPDATE accounts …;
   → send "payment made" to the message queue          ← not in the transaction
COMMIT;                                                 ← and this can still fail
```

If the commit fails after the message was sent, the message is a lie. If the message is sent after
the commit and the process dies in between, it is never sent at all. There is no ordering of those
two lines that is safe, and noticing that is most of the battle.

The real answers are patterns rather than a keyword: write the message into a table **inside** the
transaction and have a separate process deliver it, or make the receiving side tolerate being told
twice. Two-phase commit exists and is a genuinely distributed protocol with its own failure modes,
and it is not something to reach for casually.

## And the slogan about NoSQL

You will be told that relational databases are ACID and that the rest are not. That was a fair
summary in 2010 and it is not a description of the current landscape: several document and
key-value stores now offer real transactions, some across multiple keys, and a few relational
setups give up durability guarantees for speed on purpose.

The useful habit is not to ask whether something is ACID. It is to ask the four questions
separately — *what happens if this half fails, what rules are actually enforced, what can another
connection see, and what survives a power cut* — because a product answers those one at a time,
and so does a configuration file.
