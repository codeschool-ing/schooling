---
title: One leader, two followers, and the high watermark
version: 1
---

**Every partition has one leader, which takes every write and serves every read, and its other
replicas are followers, which copy the leader's log by fetching from it exactly as a consumer
would.** The followers are not a standby that is synchronised now and then. They are permanently
asking the leader *what do you have after offset N?*, appending what comes back to their own log,
and asking again.

The common wrong picture is a leader that pushes each write to its followers and waits for them
before saying anything. Nothing is pushed: the followers pull, at their own pace, and the leader
only learns how far each follower has got from the offset in its next fetch. That is why a slow
follower slows nobody down, and why the leader can tell, at any moment, which followers are
keeping up.

## The same bytes, three times

Send three hundred sales to the three-copy topic, and look at where they landed:

```
ubuntu@stream:~/work$ python tills.py --count 300 --rate 0
```

@@COPIES@@

## What a consumer is allowed to read

A record written to the leader is not yet safe. If the leader died the next instant, a follower
that had not fetched it would take over, and the record would be gone. So the leader keeps one
more number per partition, the **high watermark**: the first offset that is **not yet on every
in-sync replica**. Everything below it is on every in-sync copy, and is called **committed**.

**A consumer is only ever given records below the high watermark.** A record above it exists on
the leader's disk, and no consumer sees it until the followers have caught up. That rule is what
makes a failover invisible to readers: no consumer can have read a record that the new leader
does not have.

@@fig:l5-high-watermark@@

The followers learn the high watermark from the leader in the answers to their fetches, and keep
their own copy of it, so a follower that becomes leader knows where committed data ends. The
records it holds above that point may be on its disk and not on the others', and the leader
elections in the later sections of this lesson are careful about exactly those.

**Leaders also serve the reads, by default.** A consumer of partition 1 talks to the leader of
partition 1, wherever it is. Since Kafka 2.4 a consumer can be allowed to read from a follower in
its own rack or zone, which saves money in a cloud where traffic between zones is charged; the
last section of this lesson comes back to it.
