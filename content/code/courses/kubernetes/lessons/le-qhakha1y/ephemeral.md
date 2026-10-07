---
title: A volume that lives as long as the pod
version: 1
---

A volume is a directory a pod's containers can mount, declared in the pod under `volumes` and placed
in each container with `volumeMounts`. **What kind of volume it is decides how long the data lives.**
The simplest kind, `emptyDir`, is created empty when the pod lands on a node and removed when the pod
goes away:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scratch
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/started; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
```

The container writes the time it started into the volume. Then the pod is deleted and created again:

```
ana@laptop:~/shop$ kubectl apply -f scratch.yaml
pod/scratch created
ana@laptop:~/shop$ kubectl exec scratch -- cat /data/started
Tue Oct  6 17:55:47 UTC 2026
ana@laptop:~/shop$ kubectl delete pod scratch
pod "scratch" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f scratch.yaml
pod/scratch created
ana@laptop:~/shop$ kubectl exec scratch -- cat /data/started
Tue Oct  6 17:56:21 UTC 2026
```

**Two different times: the second pod got a new, empty directory.** Nothing of the first one survived,
which is exactly what `emptyDir` promises. It does survive a container restart inside the same pod,
because the pod, and therefore the volume, is still there; that makes it the right place for a cache,
for files two containers in one pod share, and for the writable `/tmp` of lesson 25.

It is the wrong place for anything the shop must not lose: orders, uploads, a database's files. Pods
are deleted by rollouts, by evictions and by node failures, as lessons 10 and 32 show, and the data
has to outlive every one of them. That needs storage the pod does not own, which is what the rest of
this lesson builds.
