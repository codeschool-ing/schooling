---
title: What runs on spot, and what does not
version: 1
---

The question is not whether an application is important. A production web service can run mostly
on spot and a test database must not. **The question is what an interruption costs**: if any one
instance can disappear with two minutes' notice and the work carries on elsewhere, spot is a
discount; if one instance disappearing loses something or stops everything, it is a gamble that
will lose eventually.

## What fits

- **Stateless web and API instances behind a load balancer.** Each request is short, the session
  lives in a shared store, and an instance leaving the target group costs the requests it was
  serving at that moment, which the load balancer can let finish. A mixed group with an on-demand
  base, as in the previous section, is the standard shape.
- **Queue workers.** A worker that is interrupted mid-message never deletes it, so the message
  becomes visible again and another worker takes it. The cost of an interruption is one message
  processed twice, which the consumer has to tolerate anyway (lesson 21).
- **Batch jobs that checkpoint.** A render, a training run or a report that writes its progress to
  S3 every few minutes loses at most those minutes. Without checkpoints, the same job loses
  everything since it started, and a long one may never finish.
- **CI runners and build agents.** A build that is interrupted is run again, and builds are already
  designed to be repeatable.
- **Containers on a cluster of instances.** The orchestrator moves the containers of a lost node;
  Fargate Spot (lesson 9) and Karpenter's spot provisioning on EKS (lesson 12) are this idea in
  those services.

## What does not

- **A single instance holding state**: one database server, one file server, one instance whose
  disk is the only copy of something. Lesson 3's instance store is gone at the first interruption.
- **Long jobs that cannot checkpoint**, because the longer the job, the more likely an interruption
  lands inside it, and every one starts it again.
- **Anything whose start-up is longer than its expected life between interruptions.** An application
  that needs twenty minutes to warm its caches gains nothing from an instance it loses every hour.
- **The minimum a service needs to stay up.** That is what the on-demand base is for: if the
  service needs three instances to answer at all, three of them are on demand.

## A check before moving something to spot

Three questions decide it, and each has an answer you can test without spot at all:

1. **Can any one instance be terminated now without losing data?** Terminate one in a test group
   and see.
2. **Does the work it was doing get done anyway?** For a queue, the message comes back; for a
   request, the client retries; for a job, it resumes from a checkpoint.
3. **Can the group survive losing several at once?** An interruption is per pool, so a group of one
   type in one zone can lose all its spot instances together. Several types and zones, and an
   on-demand base, are the answer.

**A workload that passes all three is already the kind lesson 4 asked for**: instances replaced,
never repaired. Spot does not ask for a different architecture. It charges less for the one that
auto scaling groups already assume, and charges in interruptions for any instance that was secretly
a pet.
