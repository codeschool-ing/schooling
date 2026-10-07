---
title: The cluster autoscaler adds and removes machines
version: 1
---

Both autoscalers so far work inside the nodes the cluster has. When the HPA adds pods that do not fit,
they stay `Pending`, as lesson 19's fifth copy did. **The cluster autoscaler watches for exactly that**:
pods that cannot be scheduled for lack of room. It asks the cloud for another machine in a node group
that would fit them, and the new node joins the cluster and takes the pods.

It works in the other direction too. A node whose pods could all fit elsewhere, for a while, is
drained, respecting PodDisruptionBudgets as lesson 32's drain did, and the machine is returned.

kind cannot grow: its nodes are containers made when the cluster is created, so nothing here was run,
and this section only describes.

| | cluster autoscaler | node auto-provisioning (Karpenter, GKE, AKS) |
|---|---|---|
| chooses | how many machines, in node groups you defined in advance | the machine type too, from what the pending pods ask for |
| reacts to | pods `Pending` for lack of room | the same |
| removes | nodes whose pods fit elsewhere | the same, and can replace nodes with cheaper ones |

Two settings decide most of its behaviour. **Requests**, again: it adds a node when requests do not
fit, never because of usage, so the waste of lesson 21 becomes machines bought for nothing. And
**PodDisruptionBudgets and `safe-to-evict` annotations**: a pod it may not move keeps its node alive,
so one badly configured pod can keep a whole machine on the bill.

The four together make the full loop: the HPA adds pods under load, the scheduler places them, the
cluster autoscaler buys a machine when they do not fit, and when the load goes, the HPA removes pods
and the cluster autoscaler gives the machine back.
