---
title: Was it worth it? The arithmetic
version: 1
---

The change is real and small; its cost is real and continuous. Deciding between them is a sum,
and the sum has two halves that are almost always done with different units — which is how
changes like this one survive. Put both in the same unit and the decision mostly makes itself.

## What it gives back, per day

The server's own numbers, from the before-and-after section: 0.107 milliseconds a call before,
0.089 after, so **0.018 milliseconds saved per call**. In the workload the statement ran about 575
times a second. So:

| | |
|---|---|
| saved per second of traffic | 575 × 0.018 ms ≈ 10 ms |
| as a share of one processor | about 1% |
| over a day at that rate | 10 ms × 86 400 ≈ 900 s, fifteen minutes |

Fifteen minutes of server time a day sounds like something. Spread over a day it is one processor
one per cent less busy — which matters only if the server is short of processor time, and the knee
in lesson 23's curve is where that question is answered.

And what each person gets is **0.046 milliseconds** off a page they open, the difference between
the pgbench medians. Nobody can see that. A human notices a delay of around a tenth of a second; this
is two thousand times smaller.

## What it costs, per day

- **60 MB** more on the disk, in every backup, and competing for memory with the tables that the
  slow statements need;
- one more index entry on every order written, too small to see in this workload and not zero;
- one more thing the next person has to understand.

## The same sum on a change that was worth it

Lesson 2's index on `seller_id` took the seller dashboard from a mean of **35.49** milliseconds to
**11.26**, about 24 milliseconds a call, and the dashboard ran about 36 times a second:

| | customer-orders index | seller_id index |
|---|---|---|
| saved per call | 0.018 ms | 24 ms |
| calls a second | 575 | 36 |
| saved per second | about 10 ms | about 870 ms |

**The seller index gave back nearly a whole processor; this one gives back a hundredth of one.**
The two changes look the same in a code review — one `CREATE INDEX` line each, both making a
query faster, both justified by a plan. The difference only appears when the saving is multiplied by
how often the query runs, which is the same lesson the tally taught in lesson 2: **it is the total
that matters, not the improvement per run.**

## The decision

On this database, with this workload, the new index is not worth its 60 MB. It made a statement that
was already among the cheapest in the application a little cheaper, while the tag search and the
pending count still took most of the server's time. The time spent on it would have been
better spent on either of those, and lessons 8 and 9 show what that looks like.

There is a version of this database where the answer is yes: one where the customer's order list
is the statement at the top of the tally, the server is near the knee, and the 60 MB fits in memory
comfortably. The arithmetic is the same; only the numbers change. **That is the point of doing it
on paper**: the decision belongs to the numbers of the database in front of you, not to the
textbook that recommended the index.
