---
title: Testing a consumer for duplicates
version: 1
---

**The test for a consumer that claims to be idempotent is to run it twice over the same input
and compare what it leaves behind.** If the second run changes anything, the claim is false. It
is a short test, and it catches the defect that matters most in this lesson, because a duplicate
in production is invisible until somebody counts the shelf.

The input is the topic, which keeps what it was given, so replaying it is free. The output is
whatever the consumer writes; here, the rows of `stock`, dumped to a file after each run and
compared with `diff`, which prints nothing when two files are the same.

## The deduplicating sink

```
ubuntu@stream:~/work$ rm stock.db
```

@@TEST-DEDUP@@

## The sink without ids

The same test against the version that only subtracts:

```
ubuntu@stream:~/work$ rm stock.db
```

@@TEST-NAIVE@@

## What else the test should do

A run twice over the same input is the minimum. The failures lessons 7 and 8 have shown are each
one more case for the same comparison:

- **a crash in the middle**: stop the consumer at a point inside a batch, start it again, and
  compare with a run that was never stopped. The two `--crash-after` runs in this lesson are that
  test done by hand;
- **a duplicate in the input**: write the same event twice to the topic, as a producer retry
  would, and compare with the output of the input without it;
- **reordering**: for a sink that keeps versions, deliver an old version after a new one and check
  that the new one stays.

Each is a few lines in whatever test framework the team uses, and each fails loudly on a consumer
that would otherwise be wrong by a few copies of a book, quietly, for ever. Lesson 16 comes back
to reprocessing, which is this same replay done on purpose in production.
