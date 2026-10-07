---
title: Drift, and going back with git
version: 1
---

Somebody, in a hurry during an incident, scales the shop by hand:

```
ana@laptop:~/shop/platform$ kubectl scale deployment shop --replicas=5
deployment.apps/shop scaled
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] "
-  generation: 3
+  generation: 4
-  replicas: 5
+  replicas: 2
```

**The cluster and the repository now disagree, and `diff` says exactly how**: five replicas live, two
in git. This is drift, and it is how clusters become impossible to rebuild: every manual fix that was
never written down is a difference that the next rebuild silently undoes. Applying the repository
puts the cluster back:

```
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
ana@laptop:~/shop/platform$ kubectl get deployment shop
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   2/2     2            2           13s
```

A GitOps tool does this on its own, which is both its strength and the reason teams switch the
automatic correction off for some fields. An autoscaler, lesson 33's, also changes `replicas`, and a
tool that fights it every few minutes would undo the scaling. The usual fix is to leave `replicas` out
of the manifest for any Deployment an autoscaler manages.

## Rolling back is a commit

1.1 turns out to be bad. The way back is the same as the way forward, through git:

```
ana@laptop:~/shop/platform$ git revert --no-edit HEAD >/dev/null && git log --oneline
ad5e381 Revert "shop 1.1"
be6246c shop 1.1
efea582 shop 1.0, two copies
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
ana@laptop:~/shop/platform$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image}"; echo
shop:1.0
```

`git revert` makes a new commit that undoes the old one, the cluster follows, and the history now shows
the release, the problem and the reversal, in order. Compare `kubectl rollout undo` from lesson 35: it
is faster in an emergency, but it leaves the repository saying 1.1 while the cluster runs 1.0, which
is drift again, waiting for the next apply to bring the bad version back.
