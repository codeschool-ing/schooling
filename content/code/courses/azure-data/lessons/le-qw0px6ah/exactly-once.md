---
title: Exactly once, and what earns the name
version: 1
---

**Exactly once is the result of at-least-once delivery and a sink that makes the second delivery
harmless.** No setting on an event hub switches it on, because the event hub's half of the work is
only delivery; what happens to the result is decided where the result is written. This section runs
the other way of earning it, and then reads what the Azure services mean when they use the words.

## The sequence number as a watermark

**Within a partition, a replay re-reads events in the same order with the same sequence numbers.**
So a reader can store, beside its results and in the same write, the last sequence number it applied,
and skip anything at or below it. That is the `guard` mode of `totals.py`: the totals and the last
sequence number live in one blob, uploaded in one operation, so the two can never disagree after a
crash. The same crash and restart:

```
ana@laptop:~/azure$ python totals.py guard 5
seq 0  o-301 c-17   4590  added, with its sequence number
seq 1  o-302 c-02  12800  added, with its sequence number
seq 2  o-303 c-17    990  added, with its sequence number
  checkpoint at seq 2
seq 3  o-303 c-17    990  added, with its sequence number
seq 4  o-304 c-05   2350  added, with its sequence number
  crash
ana@laptop:~/azure$ python totals.py guard
seq 3  o-303 c-17    990  skipped, already in the state
seq 4  o-304 c-05   2350  skipped, already in the state
seq 5  o-305 c-02   1500  added, with its sequence number
  checkpoint at seq 5
seq 6  o-306 c-17   7200  added, with its sequence number
totals: c-02 14300  c-05 2350  c-17 13770
```

**The replay was caught**: sequence numbers 3 and 4 came back, were found at or below the 4 stored
in the state, and were skipped. `c-05` is 2,350, right. **And `c-17` is 13,770, which is still wrong**,
by 990: the producer's retry is a second event with a sequence number of its own, 3, which the first
run applied as new. A watermark of sequence numbers catches what the reader repeats and is blind to
what the producer repeated. The order-id key of the last section caught both, which is why a key
from the business, decided before the first send, is the stronger fix.

Two conditions make the watermark work at all, and both are easy to break. **The state and the
sequence number must be written together**: written as two blobs, a crash between them is the same
problem again, one level down. And **the watermark is per partition**: a reader of four partitions
keeps four, because sequence number 5 in partition 0 and in partition 3 are unrelated, as lesson 22
showed.

## What the services mean by it

**This part is from Microsoft's documentation and was not run.** Stream Analytics is the one service
in this course that uses the words, and it is precise about where they stop: exactly-once
**processing** inside the job, meaning a job that restarts after a failure produces the same results
from the same input, and at-least-once **delivery** to outputs. A row of the checkout counter can be
written to its SQL table twice after a failure, and the table's key, or an upsert, is what makes that
harmless. The promise ends at the job's edge, which is the shape of every exactly-once claim: it is
true inside one system and stops where the result leaves it.

**So the question to ask of any pipeline is where its idempotency lives**, stage by stage. For
Quitanda's payments: the shop's producer may send twice, so the event carries the order id; Event
Hubs delivers at least once; the reader may replay, so it writes by order id; the totals are computed
from the payments rather than incremented. Every stage that can repeat something is followed by a
stage that does not mind. That is what exactly once is made of, and it is designed rather than
configured.
