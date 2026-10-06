---
title: The loop, done by hand
version: 1
---

**GitOps rests on one rule: the desired state of the cluster is whatever a git repository says**, and
every change to the cluster is a change to that repository first. The repository here is called
`platform`, and holds the shop as a Kustomize directory, from lesson 38:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop/platform$ git log --oneline
efea582 shop 1.0, two copies
```

The loop has two steps, and the first is to compare:

```
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] " | head -n 5
+  creationTimestamp: "2026-10-06T21:07:25Z"
+  generation: 1
+  name: shop
+  namespace: default
+  uid: 990e0278-fe65-43f7-86c2-77048fd4c762
```

`kubectl diff` asks the API server what applying would change. Here the Deployment does not exist yet,
so everything is new. Then the second step, apply, and the comparison again:

```
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop created
ana@laptop:~/shop/platform$ kubectl diff -k shop; echo "diff exit status: $?"
diff exit status: 0
```

**An exit status of 0 from `kubectl diff` means the cluster matches the repository**; 1 means it does
not. That one number is what a GitOps tool computes, for every application, every few minutes.

## A change goes through git

Version 1.1 is released by changing the file and committing, not by touching the cluster:

```
ana@laptop:~/shop/platform$ sed -i 's/image: shop:1.0/image: shop:1.1/' shop/deployment.yaml
ana@laptop:~/shop/platform$ git commit -qam "shop 1.1" && git log --oneline
be6246c shop 1.1
efea582 shop 1.0, two copies
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] "
-  generation: 1
+  generation: 2
-      - image: shop:1.0
+      - image: shop:1.1
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
```

The commit says who changed what and when, and why if the message is any good. In a team it arrives
through a pull request, so the change was reviewed before it existed anywhere, and the cluster's
history is the repository's history. **Nobody needed access to the cluster to make the change**, only
to the repository, which is the security argument for GitOps as much as the convenience one.
