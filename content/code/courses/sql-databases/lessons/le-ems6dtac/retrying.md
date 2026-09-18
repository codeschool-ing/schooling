---
title: Retrying, which is the half people leave out
version: 1
---

Two sections of this lesson end with the database refusing a transaction and telling you to run it
again. That is not an error condition to log and move past: it is how those features work, and an
application without a retry loop has turned a concurrency mechanism into an error page.

## Which errors mean "run it again"

The standard settled this and both engines follow it. **SQLSTATE class 40 is the transaction
rollback class**, and it is the whole rule:

| code | name | where it comes from |
|---|---|---|
| `40001` | serialization failure | `SERIALIZABLE`, or a conflicting update at `REPEATABLE READ` |
| `40P01` | deadlock detected | PostgreSQL, a lock cycle |
| `1213` | deadlock | MySQL's number for the same thing, class `40001` |

Anything starting `40` means: nothing was written, nobody is at fault, and the same transaction may
well succeed on a second attempt.

Just as important is what is **not** on the list:

```
23505  unique violation        the row is genuinely a duplicate — retrying inserts it again
23503  foreign key violation   the parent is genuinely missing
23514  check violation         the value is genuinely out of range
42601  syntax error            the query will be wrong for ever
```

Retrying a class 23 error is a loop that runs until something gives up. Retrying a `42` is a loop
that never ends. **Retry on the class, not on the fact that something failed** — an
`except: retry` around a whole transaction is one of the more expensive ways to hide a bug.

MySQL's `1205`, lock wait timeout, sits in between. Retrying it is reasonable once, and if it
happens often the answer is in the previous section rather than in a loop.

## Retry the transaction, not the statement

```
attempt 1
    BEGIN
    SELECT …            ← the values this attempt read
    UPDATE …
    COMMIT              → 40001

attempt 2
    BEGIN               ← from the very beginning
    SELECT …            ← re-read: the world has changed, and that is the point
    UPDATE …
    COMMIT              → ok
```

Two reasons, and the second is the one that matters.

The transaction is already dead — in PostgreSQL every statement after the failure is refused until
you roll back, so there is nothing to resume.

And the retry has to **make its decision again**. A serialization failure means the premise your
transaction read turned out to be false. Re-running the last statement with the values you read the
first time writes the wrong answer faster. Everything the transaction reads must be read again, so
the loop has to go around the reads as well as the writes.

That is why this is a structural thing rather than a `try` block: whatever code decides what to
write has to sit inside the retryable unit.

## The shape of the loop

```
for attempt in 1 … 5:
    begin
    run the work, reads and writes
    commit
    → success, stop

    on SQLSTATE class 40:
        rollback
        wait a short random time, longer each attempt
        carry on

    on any other error:
        rollback and give up — this one will not get better

after 5 attempts:
    give up, and log it loudly
```

Four details worth writing down:

**Cap the attempts.** A transaction that conflicts every time — two jobs permanently fighting over
the same row — would otherwise retry for ever and consume a connection doing it.

**Back off, and add randomness.** Two transactions that both retry immediately collide again, and
then again. A short wait that grows, with a random component so they do not stay in step, turns a
collision into a queue.

**Log the retries.** They are invisible when they work, and *"this transaction succeeds on the
fourth attempt every time"* is a design problem that a silent loop will hide for a year. Count
them; a rate is a signal.

**And give up loudly.** Exhausting the retries is a real failure and deserves the same attention as
any other, with the SQLSTATE in the message so the next person knows which kind it was.

## The retry has to be safe to run twice

Which is the second argument for the rule in the last section. If the transaction sends an email,
charges a card or posts to a queue, attempt 1 did those things before it failed — and attempt 2
does them again. The database rolled back its own work and has no view of anything else.

So: keep side effects out of the transaction, and where the work must be repeatable, make it
idempotent — a natural key that a second insert collides with, an `ON CONFLICT DO NOTHING`, an
identifier the receiving system recognises as one it has already seen.

## Where it should live

Once, in one place: a helper that takes a block of work and runs it inside the loop. Scattering
retry logic through the code guarantees that the transaction somebody adds next month will not have
it.

Several frameworks provide one — and several do not, and some provide one that retries the
statement rather than the transaction, which is the version that does not work. It is worth
reading the one you have rather than assuming.

And to close the loop this lesson opened: **choosing `SERIALIZABLE` and choosing to write this are
the same decision.** The level is not harder to use than the others because it is slower. It is
harder because it hands you an error that means *try again*, and answering that is the application's
job.
