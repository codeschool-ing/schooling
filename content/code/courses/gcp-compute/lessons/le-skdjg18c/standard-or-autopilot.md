---
title: Standard or Autopilot
version: 1
---

Google's own guidance is to start on Autopilot unless something rules it out, and that is a fair
default. **The useful version of the question is not which is better, but which of your
workloads would be refused or overcharged by Autopilot.** If none are, Autopilot removes a whole
category of work; if some are, the answer may be one cluster of each.

## The questions, in order

1. **Does anything need what section 04 refuses?** A privileged agent, a host path, a custom kernel
   module, SSH to debug. If yes, that workload needs Standard, whatever the price.
2. **How full would Standard's nodes be?** Run `autopilot.py` with the real pod shapes. If the nodes
   would be well filled around the clock, Standard is cheaper by the margin section 03 showed.
3. **Is the load uneven?** A cluster that is busy by day and nearly empty at night pays for empty
   nodes on Standard unless its autoscaling is tuned carefully, and pays for nothing on Autopilot.
4. **Who would look after the nodes?** Upgrade strategies, pool sizes, machine types and node
   security are a recurring job. A team of two that would rather not have it has a reason for
   Autopilot that no price comparison shows.

## The shop's answer

| workload | what decides it | where |
|---|---|---|
| `web`, `orders` | small, uneven, nothing privileged | Autopilot |
| `photos` resizing | interruptible batch | Autopilot, Spot pods |
| a log agent needing host paths | refused by Autopilot | Standard, or the platform's own logging instead |

For the shop the last row resolves itself: GKE already ships logs to Cloud Logging, which
`gcp-operations` covers, so the agent that needed host paths is not needed at all. One Autopilot
cluster carries everything, for one cluster fee.

## Changing your mind

A cluster's mode is fixed when it is created: you cannot convert a Standard cluster to Autopilot or
back. Moving means creating the other kind and redeploying onto it, which is the same work as any
cluster migration and the reason to answer the four questions before the first production
workload lands rather than after. The Kubernetes objects themselves mostly move unchanged, apart
from anything section 04 refuses, so the cost of the move is the migration, not a rewrite.
