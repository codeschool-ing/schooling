---
title: A Deployment manages ReplicaSets
version: 1
---

A ReplicaSet keeps a number of identical pods. It cannot change what those pods are: give it a new
image and it leaves the existing pods alone, because they still match its selector. **Changing the
pods is a Deployment's job, and it does it by making a second ReplicaSet** rather than editing the
first.

## Scaling is the number, and nothing else

```
ana@laptop:~/shop$ kubectl scale deployment web --replicas=5
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl get deployment web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    5/5     5            5           7s
ana@laptop:~/shop$ kubectl scale deployment web --replicas=2
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl get pods -l app=web
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-lvz57   1/1     Running   0          6s
web-768c88b7c7-wbwkb   1/1     Running   0          12s
```

`scale` writes `replicas` on the Deployment, which passes the number to its ReplicaSet, which makes
or deletes pods. Going down from five to two, the controller chose which three to delete, by a ranking: pods
not yet ready go first, then pods on the nodes that hold the most copies, then the ones that have
been ready for the shortest time. That is why one original, `wbwkb`, and one newcomer, `lvz57`,
are the two left.

## A new template is a new ReplicaSet

```
ana@laptop:~/shop$ kubectl set image deployment/web shop=shop:1.1
deployment.apps/web image updated
ana@laptop:~/shop$ kubectl get replicasets -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   0         0         0       13s
web-798bdd9498   2         2         2       1s
ana@laptop:~/shop$ kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
NAME                   IMAGE
web-768c88b7c7-lvz57   shop:1.0
web-768c88b7c7-wbwkb   shop:1.0
web-798bdd9498-nkhm8   shop:1.1
web-798bdd9498-rx9tr   shop:1.1
```

`set image` changed the pod template, so the template's hash changed, so the Deployment made
`web-798bdd9498` for it and moved the count across: the new ReplicaSet wants two, the old one wants
zero. The listing caught the moment between: two `shop:1.1` pods running, and the two `shop:1.0` pods
on their way out. **The old ReplicaSet is kept, empty**, and that empty object is what makes a
rollback a one-line command: lesson 35 does the update properly, with the order and the pace under
control, and undoes it.

## Why you almost never create one yourself

What happens if the ReplicaSets themselves are deleted?

```
ana@laptop:~/shop$ kubectl delete replicaset -l app=web --cascade=foreground
replicaset.apps "web-768c88b7c7" deleted from default namespace
replicaset.apps "web-798bdd9498" deleted from default namespace
ana@laptop:~/shop$ kubectl get replicasets -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-798bdd9498   2         2         2       6s
```

Both were deleted, and six seconds later the Deployment had made the one it needs again, with the
same name because the template, and so its hash, had not changed. A ReplicaSet created by hand
would get none of this: no history, no new ReplicaSet for a new image, nobody to recreate it. **So the
rule is simple: write Deployments, and read ReplicaSets** when you need to know which version a pod
belongs to.

| | ReplicaSet | Deployment |
|---|---|---|
| keeps a number of pods running | yes | through its ReplicaSets |
| changes the pods when the template changes | no | yes, with a new ReplicaSet |
| keeps the previous version for rollback | no | yes, as an empty ReplicaSet |
| written by you | almost never | almost always |
