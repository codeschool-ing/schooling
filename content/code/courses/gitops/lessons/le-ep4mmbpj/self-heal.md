---
title: Self-healing, and what to leave alone
version: 1
---

**`selfHeal` makes Argo CD react to the cluster, not only to Git.** The controller watches the
objects it manages, and a change that makes them differ from Git triggers a sync, without waiting
for the timer.

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=6
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           2m26s
```

The scale to six lasted a few seconds. Lesson 1's loop needed up to one interval to notice; Argo CD
noticed the change as an event and reverted it almost at once. The Application's events record that
it happened and why, which is the beginning of lesson 12's audit trail:

```
ana@laptop:~/fleet$ kubectl -n argocd get events --field-selector involvedObject.name=bulletin-staging --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep Operation | tail -n 4
OperationStarted     Initiated automated sync to '370bc6ed7afdfe4b89b53772873d1889026c7c4b'
OperationCompleted   Partial sync operation to 370bc6ed7afdfe4b89b53772873d1889026c7c4b succeeded
OperationStarted     Initiated automated sync to '370bc6ed7afdfe4b89b53772873d1889026c7c4b'
OperationCompleted   Partial sync operation to 370bc6ed7afdfe4b89b53772873d1889026c7c4b succeeded
```

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

```
ana@laptop:~/setup$ tail -n 10 bulletin-staging.yaml
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - RespectIgnoreDifferences=true
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
ana@laptop:~/setup$ kubectl apply -f bulletin-staging.yaml
application.argoproj.io/bulletin-staging configured
ana@laptop:~/setup$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/setup$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   5/5     5            5           2m36s
ana@laptop:~/setup$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
```

Now a scale lasts, and the Application stays `Synced`, because the one field that differs is a field
it was told not to compare. **This is a deliberate hole in the reconciliation**, and it should be
exactly as wide as the thing that owns the field: one field, one kind. Ignoring a whole object, or
turning `selfHeal` off for an application because one field fights, gives up the guarantee for every
other field too.

Nothing owns `replicas` here, so take the `ignoreDifferences` block and the `syncOptions` back out,
apply the file again, and Argo CD puts the deployment back to three.
