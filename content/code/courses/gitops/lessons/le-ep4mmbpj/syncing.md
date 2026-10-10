---
title: Sync status and health are two questions
version: 1
---

**"Is the cluster what Git says?" and "Is what is running working?" are different questions, and
Argo CD answers them separately.** Sync status compares the live objects with the rendered
manifests. Health asks each object whether it is doing its job: a Deployment is healthy when its
replicas are available, a Service when it exists, a pod when it runs and passes its probes.

@@figure axes

Each of the four combinations means something:

| sync | health | what it usually means |
|---|---|---|
| Synced | Healthy | the goal: Git describes what runs, and it works |
| OutOfSync | Healthy | Git changed and nothing applied it yet, or somebody changed the cluster |
| Synced | Degraded | Git was applied faithfully, and what Git says does not work, like lesson 2's missing image |
| OutOfSync | Degraded | something is wrong on both counts; read the sync first |

The third row is the one people misread. **A Synced, Degraded application is not Argo CD failing.**
It did exactly its job, and the bug is in the repository.

## Syncing by hand

With no sync policy, Argo CD only reports. Applying is a command:

@@capture sync

The table is the controller's account of the operation: each object, the `kubectl` result, and the
revision it applied, `@@rev`. Afterwards the Application is `Synced` and `Healthy`, and the objects
carry the tracking annotation:

@@capture after-sync

**The revision is recorded, not guessed.** Anybody with read access to the `argocd` namespace can
ask which commit staging is running, and the answer comes from the controller that applied it.
