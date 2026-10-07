---
title: A version that crashes, and the way back
version: 1
---

The shop exits at start when the variable `CRASH` is set, which makes a convenient bad release.
Changing an environment variable changes the pod template, so it is a rollout like any other:

```
ana@laptop:~/shop$ kubectl set env deployment/shop CRASH=1
deployment.apps/shop env updated
ana@laptop:~/shop$ kubectl rollout status deployment/shop --timeout=10s
Waiting for deployment "shop" rollout to finish: 1 out of 4 new replicas have been updated...
error: timed out waiting for the condition
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS             RESTARTS      AGE
shop-5cdd5f6b94-nwssx   0/1     CrashLoopBackOff   3 (15s ago)   50s
shop-997ffd576-2cg2c    1/1     Running            0             81s
shop-997ffd576-dvvbf    1/1     Running            0             80s
shop-997ffd576-j8ql6    1/1     Running            0             80s
shop-997ffd576-xjdql    1/1     Running            0             79s
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- -T 2 shop || echo FAILED; sleep 0.1; done" | cut -d" " -f1,2 | sort | uniq -c
    300 shop 2.0
```

**The rollout stopped by itself, at one pod.** The new pod never became ready, so with
`maxUnavailable: 0` no old pod was allowed to leave, and with `maxSurge: 1` no second new pod was
allowed in. The four old pods kept serving, and the count shows all three hundred requests answered by
`2.0`. The settings from the first section did more than pace the update; **they capped how much of the
service a broken version could reach.** With the default `25%` of each, one old pod would have gone too.

Nothing rolls it back on its own. After `progressDeadlineSeconds`, ten minutes by default, the
Deployment marks itself as failing to progress, and that is a condition for a person or a pipeline to
read. The `error` above is not that: it is `kubectl rollout status` giving up after the ten seconds it
was told to wait.

## History

Every change to the template made a ReplicaSet, and the Deployment keeps the old ones, ten by default,
as its history:

```
ana@laptop:~/shop$ kubectl rollout history deployment/shop
deployment.apps/shop 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
4         <none>
5         <none>

ana@laptop:~/shop$ kubectl rollout history deployment/shop --revision=4 | grep -E "Image|CRASH"
    Image:	shop:2.0
```

Five revisions: the first apply, `1.1`, the `preStop` patch (it changed the template too), `2.0`, and
the crash. The `CHANGE-CAUSE` column is empty because nothing filled it; it reads the
`kubernetes.io/change-cause` annotation, which is easy to set and just as easy to leave describing the
wrong revision. **The template of a revision is the reliable record**, and `--revision` shows it:
revision 4 is `2.0` without `CRASH`. Then:

```
ana@laptop:~/shop$ kubectl rollout undo deployment/shop
Warning: resource deployments/shop was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/shop rolled back
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS        RESTARTS     AGE
shop-5cdd5f6b94-nwssx   0/1     Terminating   4 (5s ago)   81s
shop-997ffd576-2cg2c    1/1     Running       0            112s
shop-997ffd576-dvvbf    1/1     Running       0            111s
shop-997ffd576-j8ql6    1/1     Running       0            111s
shop-997ffd576-xjdql    1/1     Running       0            110s
ana@laptop:~/shop$ kubectl rollout history deployment/shop
deployment.apps/shop 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
5         <none>
6         <none>
```

`undo` copies the template of the previous revision back into the Deployment, which makes an ordinary
rollout towards a ReplicaSet that already exists. The crashing pod is on its way out and the four good
ones never moved. **The history lost revision 4 and gained 6**: the same template does not get two
numbers, so it moved to the top. `kubectl rollout undo --to-revision=2` would go to a specific one.

The warning matters more than it looks. Every change in this lesson was made by a command, so
`shop.yaml` still says `shop:1.0`, and the next `kubectl apply -f shop.yaml` would quietly take the shop
back to `1.0`. **In a team the file is the truth, and the fix goes into the file:** `undo` buys the
minutes to make it.
