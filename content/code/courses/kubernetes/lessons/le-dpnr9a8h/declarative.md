---
title: Write it down, then apply it
version: 1
---

Lesson 2 created a deployment with `kubectl create deployment`, and lesson 4 scaled one with
`kubectl scale`. Those are **imperative** commands: each one is an order, and once it has run, the
only record of what was asked is your shell history. The rest of this course works the other way.
**You write the objects into files, keep the files in git, and `kubectl apply` makes the cluster
match them.** The file is the description; the cluster is a copy that is kept in step.

## A file to start from

Nobody writes a manifest from an empty page. `--dry-run=client -o yaml` makes `kubectl create` print
the object it would have sent instead of sending it:

```
ana@laptop:~/shop$ kubectl create deployment web --image=shop:1.0 --replicas=2 --dry-run=client -o yaml > deployment.yaml
ana@laptop:~/shop$ cat deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  strategy: {}
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: shop:1.0
        name: shop
        resources: {}
status: {}
```

`strategy: {}`, `resources: {}` and `status: {}` are empty fields the generator leaves in, and can be
deleted. Everything else is a complete Deployment.

## apply, and apply again

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web created
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web unchanged
```

**`apply` is safe to repeat.** The first run created the object; the second compared the file with
the cluster, found nothing to change, and said `unchanged`. That property is what lets a pipeline
run `kubectl apply -f` on every commit without knowing what is already there. When the file does
change, `kubectl diff` shows what `apply` would do before anything happens:

```
ana@laptop:~/shop$ sed -i "s/replicas: 2/replicas: 3/" deployment.yaml
ana@laptop:~/shop$ kubectl diff -f deployment.yaml
diff -u -N /tmp/LIVE-959397723/apps.v1.Deployment.default.web /tmp/MERGED-1156607339/apps.v1.Deployment.default.web
--- /tmp/LIVE-959397723/apps.v1.Deployment.default.web	2026-10-06 13:46:18.859512755 -0300
+++ /tmp/MERGED-1156607339/apps.v1.Deployment.default.web	2026-10-06 13:46:18.859512755 -0300
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"web"},"name":"web","namespace":"default"},"spec":{"replicas":2,"selector":{"matchLabels":{"app":"web"}},"strategy":{},"template":{"metadata":{"labels":{"app":"web"}},"spec":{"containers":[{"image":"shop:1.0","name":"shop","resources":{}}]}}},"status":{}}
   creationTimestamp: "2026-10-06T16:46:16Z"
-  generation: 1
+  generation: 2
   labels:
     app: web
   name: web
@@ -15,7 +15,7 @@
   uid: 55c8bb00-d7ab-4b5c-b8c7-db9fdb8dfeda
 spec:
   progressDeadlineSeconds: 600
-  replicas: 2
+  replicas: 3
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

It is a unified diff between the live object and the object as it would be after applying. Two
lines change: `replicas` from 2 to 3, which Ana asked for, and `generation` from 1 to 2, which the
API server will bump because the spec changed. The long annotation above them,
`kubectl.kubernetes.io/last-applied-configuration`, is the file as it was last applied: kubectl
keeps it on the object so that, next time, it can tell a field you deleted from the file apart from a
field somebody else set.

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web configured
```

## Drift, and how the file wins

Somebody scales by hand, as a quick fix in the middle of an incident:

```
ana@laptop:~/shop$ kubectl scale deployment web --replicas=5
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl diff -f deployment.yaml
diff -u -N /tmp/LIVE-1635049792/apps.v1.Deployment.default.web /tmp/MERGED-2555153764/apps.v1.Deployment.default.web
--- /tmp/LIVE-1635049792/apps.v1.Deployment.default.web	2026-10-06 13:46:19.795512810 -0300
+++ /tmp/MERGED-2555153764/apps.v1.Deployment.default.web	2026-10-06 13:46:19.795512810 -0300
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"web"},"name":"web","namespace":"default"},"spec":{"replicas":3,"selector":{"matchLabels":{"app":"web"}},"strategy":{},"template":{"metadata":{"labels":{"app":"web"}},"spec":{"containers":[{"image":"shop:1.0","name":"shop","resources":{}}]}}},"status":{}}
   creationTimestamp: "2026-10-06T16:46:16Z"
-  generation: 3
+  generation: 4
   labels:
     app: web
   name: web
@@ -15,7 +15,7 @@
   uid: 55c8bb00-d7ab-4b5c-b8c7-db9fdb8dfeda
 spec:
   progressDeadlineSeconds: 600
-  replicas: 5
+  replicas: 3
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

**The diff now runs backwards**: the live object says 5, the file says 3, and applying would take
the cluster back to 3. That is drift — the cluster no longer matches the description — and the diff
found it without anybody having to remember the incident. Ana applies:

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web configured
ana@laptop:~/shop$ kubectl get deployment web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    3/3     3            3           6s
```

Three again. Whether that is right depends on whether the quick fix was wanted: if it was, the
change belongs in the file and in git, so that the next `apply` does not undo it. Lesson 39 takes
this to its end, with a program that applies the repository continuously and reports drift as it
happens.

## Removing what a file created

```
ana@laptop:~/shop$ kubectl delete -f deployment.yaml
deployment.apps "web" deleted from default namespace
```

`delete -f` removes the objects named in the file, which is how an application leaves a cluster
without anybody listing its parts by hand.

| | imperative | declarative |
|---|---|---|
| example | `kubectl scale deployment web --replicas=5` | edit `replicas`, then `kubectl apply -f` |
| the record of what was asked | your shell history | the file, in git |
| run it twice | it may fail, or do it twice | `unchanged` |
| see the change first | no | `kubectl diff` |
| good for | looking around, and emergencies you then write down | everything that should still be true tomorrow |

The version of `apply` used here is the original, client-side one. `kubectl apply --server-side` moves
the comparison into the API server, which records which tool owns each field; lesson 37's Helm and
lesson 39's GitOps controllers use it, and for a person at a terminal the commands are the same.
