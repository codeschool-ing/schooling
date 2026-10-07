---
title: What a control plane costs in hours
version: 1
---

The money is small. **The hours are not**, and they are the same whatever the machines cost. Each line
below is work that a managed control plane does for you and that running your own hands back, with the
lesson of this course that showed it:

| work | how often | where it was in this course |
|---|---|---|
| upgrading the control plane, one minor version at a time | Kubernetes ships three minor versions a year | lesson 47 joins a node with kubeadm; an upgrade is the same tool |
| backing up etcd, and rehearsing the restore | daily backups, restores rehearsed on a schedule | lesson 47 takes and restores a snapshot |
| renewing certificates | kubeadm's expire after a year | lesson 47 read `364d` of residual time |
| watching the API server and etcd, and being woken when they fail | always | lesson 41 reads what they expose |
| replacing a failed control-plane machine | when it happens | lesson 32 lost a worker; a control-plane machine is harder |

**Upgrades are the line that grows.** Each minor version is supported for about fourteen months, and a
cluster may only move up one minor version at a time, so a cluster that falls two versions behind
needs two upgrades in a row, each with its own testing. A managed service runs the control-plane half
of that for you and charges extended support when you fall behind.

## Putting the hours in the sum

The comparison is then a sum with one term this course cannot fill in for you, the price of an hour of
the person who would do the work:

`own = 3 × machine × 730 + hours per month × price of an hour`

`managed = 73 dollars per cluster per month`

As an illustration only, with numbers chosen for the arithmetic and not taken from any price list:
if running the control plane took eight hours a month and an hour cost 50 dollars, the hours alone
would be 400 dollars a month, more than five times the fee, before a single machine. The point does
not depend on the figures: **for one or a few clusters, the fee is far smaller than the time it
replaces**, wherever the line between them falls for you.

The worker nodes, again, are not in either sum. Neither are the hours spent on the applications, which
are the same either way: a managed control plane does not upgrade your Deployments, write your network
policies or choose your requests.
