---
title: The three ways a machine runs out
version: 1
---

**"Big data" is not a size. It is the point where one machine runs out of something**, and there
are three things to run out of: memory, disk and time. They arrive at different sizes, and which one
you hit first decides what kind of fix you need.

**Memory runs out first, and most suddenly.** A program that keeps what it has seen in memory
works perfectly until the day the data is a little larger, and then it is killed. There is no
slowdown to warn you. Section 08 runs one into that wall on purpose.

**Disk runs out more politely.** It is ten to a hundred times larger than memory and it fills
gradually, so you see it coming. The cost is speed: a fast SSD reads perhaps 2 GB a second when it
reads in long runs, and much less when a program jumps around.

**Time runs out last, and it is the one that decides most real cases.** A job that finishes
correctly at four in the morning is useless if the report it feeds was due at eight. The
arithmetic is short and worth doing before anything is built:

| data to read | at 2 GB/s, one disk | at 200 MB/s, a cloud disk | the same, on 100 machines |
|---|---|---|---|
| 250 MB, this course's clicks | 0.1 s | 1.3 s | not worth it |
| 1 TB, a large shop's year | 8 min | 1 h 23 min | 50 s |
| 100 TB, a large website's year | 14 h | 6 days | 1 h 23 min |

The last column is the argument for a cluster in one line: **a hundred machines read a hundred
times as fast, because each reads its own share from its own disk.** No single disk, however
expensive, does that. But read the first row too. At the size of this course's data, a cluster
buys nothing at all, and the rest of this lesson is honest about that.

**The three limits are why the course exists, and they are also its warning.** Most data that
people call big fits on one machine with room to spare: 250 MB is nothing, and so is 25 GB on a
laptop with 32 GB of memory. A cluster is the answer to a question that has to be asked first,
which is *what exactly is running out?*
