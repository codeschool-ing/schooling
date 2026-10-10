---
title: Self-healing, and what to leave alone
version: 1
---

**`selfHeal` makes Argo CD react to the cluster, not only to Git.** The controller watches the
objects it manages, and a change that makes them differ from Git triggers a sync, without waiting
for the timer.

@@capture heal

The scale to six lasted a few seconds. Lesson 1's loop needed up to one interval to notice; Argo CD
noticed the change as an event and reverted it almost at once. The Application's events record that
it happened and why, which is the beginning of lesson 12's audit trail:

@@capture events

## Telling it what not to own

Lesson 2 named the case where self-healing is wrong: **a field that something else owns.** If a
HorizontalPodAutoscaler sets `replicas`, Argo CD must not put it back. The cleanest answer is to
remove `replicas` from the manifest. When that is not possible, because the manifest comes from a
chart you do not control, the Application can be told to ignore the field. Add this to the `spec`
of `~/setup/bulletin-staging.yaml`, beside `syncPolicy`:

```yaml
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

and `RespectIgnoreDifferences=true` under `syncPolicy.syncOptions`, so that a sync leaves the field
alone too, not only the comparison:

@@capture ignore

Now a scale lasts, and the Application stays `Synced`, because the one field that differs is a field
it was told not to compare. **This is a deliberate hole in the reconciliation**, and it should be
exactly as wide as the thing that owns the field: one field, one kind. Ignoring a whole object, or
turning `selfHeal` off for an application because one field fights, gives up the guarantee for every
other field too.

Nothing owns `replicas` here, so take the `ignoreDifferences` block and the `syncOptions` back out,
apply the file again, and Argo CD puts the deployment back to three.
