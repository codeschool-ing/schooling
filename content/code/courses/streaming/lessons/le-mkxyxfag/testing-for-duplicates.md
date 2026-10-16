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
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 0 sales, skipped 40 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt
ubuntu@stream:~/work$ diff run1.txt run2.txt && echo identical
identical
```

The second run applied nothing and the two dumps are the same: `diff` printed nothing, so the
`echo` ran and printed `identical`.

## The sink without ids

The same test against the version that only subtracts:

```
ubuntu@stream:~/work$ rm stock.db
ubuntu@stream:~/work$ python stock_sink.py --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt
ubuntu@stream:~/work$ python stock_sink.py --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt
ubuntu@stream:~/work$ diff run1.txt run2.txt && echo identical
1,8c1,8
< ('bk-01', 90)
< ('bk-02', 97)
< ('bk-03', 97)
< ('bk-04', 91)
< ('bk-05', 92)
< ('bk-06', 87)
< ('bk-07', 87)
< ('bk-08', 88)
---
> ('bk-01', 80)
> ('bk-02', 94)
> ('bk-03', 94)
> ('bk-04', 82)
> ('bk-05', 84)
> ('bk-06', 74)
> ('bk-07', 74)
> ('bk-08', 76)
```

`diff` prints every line, because every book's stock moved: `bk-01` from 90 to 80, `bk-06` from
87 to 74. **The test fails in the first second**, on exactly the defect that would otherwise show
up as a shelf that disagrees with the website.

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
