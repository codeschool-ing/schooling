---
title: The change feed processor and the Functions trigger
version: 1
---

**What `processor.py` lacks is what Microsoft's change feed processor provides**: many copies of the
reader sharing one feed without reading the same range twice, and taking over a range when the copy
that held it dies. This section is taught from Microsoft's documentation and was not run. The processor
is part of the .NET and Java libraries, and version 4.17.1 of the Python library has none. A search of
the installed package for it finds nothing, and what Python offers is the pull model this lesson used,
`query_items_change_feed`, with feed ranges to split the work by hand.

## Four parts

| part | what it is |
|---|---|
| the monitored container | the container whose feed is read, Quitanda's `orders` |
| the lease container | a second Cosmos DB container holding one document per feed range: who owns it, and its continuation token |
| the compute instances | the copies of the program, on one machine or many, each with a name |
| the delegate | your function, called with each batch of changes |

**A lease is `processor.py`'s checkpoint blob with an owner written on it.** Each instance takes leases
until the ranges are shared out evenly, reads the ranges it holds, calls the delegate with each batch,
and writes the new continuation token into the lease only after the delegate has returned. An instance
that stops renewing its leases loses them, and another picks them up from their last token. Start a
second instance and the leases are rebalanced between the two; stop it and they move back.

**The order of the last step is the same as the processor's in this lesson, and so is the
consequence**: a delegate that fails, or an instance that dies, after the work and before the lease is
updated means the batch is delivered again. The change feed processor is at-least-once, and the
delegate has to be safe to run twice on the same change. The processor also comes with an estimator,
which reports how far behind the leases are, and that lag is the number to put an alert on: a consumer
that has stopped looks exactly like a container with nothing new to say.

## The Azure Functions trigger

**The Cosmos DB trigger of Azure Functions is the change feed processor with the hosting done for
you.** It needs the same lease container, takes the same leases, and calls your function with each
batch. Functions adds instances as the leases call for them, up to one per lease, because one lease is
read by one instance at a time. What it does not change is the delivery: a function that fails after it
has done part of its work can see the batch again, so the rule of this lesson holds unchanged. Set
values keyed by something in the change, never add to a running total.

## What it costs

Reading the feed is reading the container: every page costs request units from the monitored
container's throughput, so a busy consumer competes with the application for the same budget of lesson
13. The lease container is a container like any other, with its own throughput and its own small bill.
And every consumer is a separate reader with its own leases, so five consumers of one feed read it five
times. That is often the right design, a view, a search index and a copy to the lake each going at
their own pace, and it is still five reads to plan for.
