---
title: "Spot capacity: cheap, and taken back"
version: 1
---

A provider buys enough machines for its busiest hour, so at most hours some of them are idle. **Spot
capacity is that idle capacity, sold at a discount on the condition that the provider can take it back
when it needs it.** AWS calls these Spot Instances and advertises discounts of up to 90% against on
demand; Google Cloud has Spot VMs and Azure has Spot Virtual Machines. The machine is the same machine.
What changes is the promise: an on-demand machine runs until you stop it, and a spot machine runs until
you stop it or the provider does.

The warning is short. AWS sends an interruption notice two minutes before it reclaims a Spot Instance;
Google Cloud gives its Spot VMs thirty seconds. That is time to finish writing a file, not to finish a
job.

## Why it is not on the sheet

The sheet has an on-demand price and a reserved price for every machine and no spot price, and that is
not an omission of `prices.py`. The published price list carries prices that are fixed until the next
version. **A spot price moves with supply and demand**, per machine type and per zone, and AWS publishes
it through a separate price history rather than in the offer files. A number printed in this lesson
would be wrong before you read it, which is the honest reason there is none.

## What it is good for

Spot fits work that can be interrupted and started again without loss:

- batch jobs split into many small pieces, such as converting a thousand videos one at a time;
- test runs of a build pipeline, where a run that dies is simply run again;
- workers that take tasks from a queue, where an unfinished task goes back on the queue;
- extra machines in lesson 4's autoscaling group, above a floor of on-demand ones.

What these have in common is that **the work, not the machine, is what must survive**. A task that
records its progress, or that can safely be done twice, loses at most one piece when its machine goes.

## What it is bad for

Spot is the wrong place for the only copy of anything. A database on a spot machine, the single
instance serving a website, a job that runs for ten hours without saving its progress: each loses
exactly what cannot be lost when the notice arrives. **The discount is paid for with availability**,
and lesson 9's whole argument was that availability is designed in, not hoped for.

The useful pattern is a mix. The floor from the section on commitments runs on reserved or on-demand
machines and keeps the service up; the work above it that can wait runs on spot and is cheap. If the
spot machines are all reclaimed at once, the service is slower, not down.
