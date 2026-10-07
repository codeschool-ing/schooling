---
title: Why nobody creates a pod by hand
version: 1
---

```
ana@laptop:~/shop$ kubectl delete pod web
pod "web" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods
No resources found in default namespace.
```

**That is the whole problem with a bare pod**: once it is gone, nothing knows it should exist. Nobody
created a ReplicaSet for it, so no controller is counting, and the cluster considers the matter
closed. A pod is deleted for many reasons besides somebody typing the command — its node is drained
for maintenance (lesson 32), the node fails, the pod is evicted because the node runs short of
memory — and each of them ends the same way for a bare pod.

So pods are almost always written as a **template inside a controller**, which then makes the pods
and replaces them:

| you want | write | lesson |
|---|---|---|
| a number of identical copies of a stateless program | a Deployment | 10 |
| copies with a stable name and a disk each | a StatefulSet | 11 |
| one copy on every node | a DaemonSet | 12 |
| a task that runs to completion | a Job, or a CronJob for a schedule | 12 |

Everything in the pod in this lesson's file — the init container, the sidecar, the shared volume —
goes unchanged into the `template:` of any of these; the controller only adds the promise that the
pod will exist.

There are still two good reasons to make a bare pod: **a throwaway pod to look around from**, like the
`probe` pods later lessons use to ask questions from inside the cluster, and a static pod written by
the node's own configuration, like the control plane of lesson 4. Neither is expected to survive.
