---
title: Drift, and what a dozen lines cannot do
version: 1
---

**Drift is a difference between the cluster and the description that nobody committed.** Someone
scales a deployment by hand during an incident, edits a value to test something, or deletes an
object by mistake. In a push-based setup that difference lives until the next deploy happens to
overwrite it. A reconciler finds it on its next pass.

## Drift, repaired

With the loop still running in the second terminal, change the cluster directly, the way somebody
in a hurry would:

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   2/5     5            2           24s
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   2/2     2            2           41s
```

And in the second terminal:

```
01:33:10 at 1949f7b
deployment.apps/bulletin configured
```

The scale to five lasted until the next pass, at most fifteen seconds, and then
`deployment.apps/bulletin configured` put it back to the two the file asks for. **The loop did not
know anything had happened.** It never compares, it never watches events; it applies the
description again, and applying is idempotent, so the only visible effect is on the field that had
moved.

That has a consequence that surprises people the first time. An emergency change made with
`kubectl` during an incident is undone within one interval. In a GitOps setup **the way to change
production quickly is a quick commit**, and lesson 2 is about making that path short enough to use
under pressure.

## What it cannot do

Three things go wrong with the loop, and each is a feature of the real tools.

**It never deletes.** Remove the Service from `staging/bulletin.yaml`, commit and push:

```
ana@laptop:~/fleet$ git diff --stat
 staging/bulletin.yaml | 14 --------------
 1 file changed, 14 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -am "staging: no service"
ana@laptop:~/fleet$ git push --quiet
ana@laptop:~/fleet$ kubectl -n staging get service
NAME       TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
bulletin   NodePort   10.96.95.6   <none>        80:30080/TCP   58s
```

And the loop, on its next pass:

```
01:33:26 at a10aba9
```

It applied what was left and said nothing, and the service is still there, because
`kubectl apply -f` only knows about the objects in the files it was given. An object removed from
Git becomes an orphan that nobody owns. Argo CD and Flux both keep a record of what they applied,
so they can delete what disappeared; it is called **pruning**, and lesson 3 turns it on.

**It cannot tell you anything.** Is the cluster in sync right now? Which commit is running? Did the
last apply fail? The loop's answer is a line of terminal output on one machine. The real tools keep
that state as Kubernetes objects that anyone with access can query, which is most of what lessons 3
and 4 show.

**It holds the keys of the whole cluster.** The loop uses your kubeconfig, which can do anything.
Lesson 11 is about giving the reconciler only the permissions its job needs.

Put the Service back with `git revert --no-edit HEAD` and `git push`, and stop the loop with
`Ctrl+C`; the next lesson replaces the bare repository with a real Git server, and lesson 3 replaces
the loop.
