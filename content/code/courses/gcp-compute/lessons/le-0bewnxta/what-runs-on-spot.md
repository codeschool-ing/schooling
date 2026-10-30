---
title: What belongs on Spot
version: 1
---

Every workload can be put on Spot, and most should not be. **The question is not "can it run there"
but "what does a preemption cost it", and the answer has to be "a little time" rather than "an
outage" or "lost data".** Sorting the shop's work by that question gives a short list each way.

## Good tenants

- **Batch work that is split into small pieces**, such as resizing the shop's photos: a preempted
  machine loses the piece it was on, and another machine picks that piece up again. Lesson 10's Cloud
  Run jobs are built the same way, on a platform that retries for you.
- **Workers that read from a queue**, where an unfinished message is simply delivered again to
  somebody else. Lesson 5's queue-driven group is this kind.
- **Build and test machines**, where a preemption means a pipeline run is retried, which costs minutes
  and nothing else.
- **The extra capacity of a stateless web service**, behind a base of standard machines, as
  section 04 described.

## Bad tenants

- **Anything holding the only copy of state**: a database, a cache nobody can rebuild quickly, a
  machine whose disk is the record.
- **Long tasks that cannot save progress**: a twelve-hour job with no checkpoint is a job that
  restarts from zero at hour eleven, and a Spot price does not pay for that.
- **The whole of a service users wait on**, because a shortage of capacity takes every machine at
  once rather than one at a time.

## The test

Before moving something to Spot, write down what happens when a machine disappears now, mid-work, with
thirty seconds' notice. If the answer is "it picks up where another left off", it belongs there, and
about 40% of its compute bill goes with it. If the answer needs a person, it does not, and no discount
pays for the person.
