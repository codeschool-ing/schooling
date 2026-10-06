---
title: A container restarts, the pod stays
version: 1
---

Two different things can happen to a pod's containers, and they are easy to confuse. **A container
that exits is restarted by the kubelet, in the same pod, on the same node, with the same address.**
A pod that is deleted is gone, and whatever replaces it is a different pod. This section is the
first of the two.

The sidecar is stopped from underneath, with the container runtime on the node, which is what a
process that crashes looks like to the kubelet:

```
ana@laptop:~/shop$ docker exec shop-worker crictl stop $(docker exec shop-worker crictl ps --name sidecar -q)
5674d0072d9983de9f02361520be8d3fad3624149d9c65214f80a9f6255a29b8
```

Eight seconds later:

```
ana@laptop:~/shop$ kubectl get pod web
NAME   READY   STATUS    RESTARTS     AGE
web    2/2     Running   1 (8s ago)   18s
ana@laptop:~/shop$ kubectl get pod web -o custom-columns=CONTAINER:.status.containerStatuses[*].name,RESTARTS:.status.containerStatuses[*].restartCount
CONTAINER      RESTARTS
```

**`RESTARTS 1 (8s ago)`, and the pod's age kept counting**: it is still the pod that was created
eighteen seconds earlier, with the same name and the same `10.244.1.2`. Per container, the shop was
never touched and the sidecar was restarted once. Anything the sidecar had kept in its own filesystem
was lost, because a restarted container starts from its image again; the `emptyDir` would have
survived, because it belongs to the pod.

## Who decides, and how often

The pod's `restartPolicy` decides, and it applies to every container in the pod:

| `restartPolicy` | a container that exits is | used by |
|---|---|---|
| `Always` (the default) | restarted, whatever its exit code | Deployments, StatefulSets, DaemonSets |
| `OnFailure` | restarted only if it exited with an error | Jobs that should retry (lesson 12) |
| `Never` | left stopped | Jobs where each attempt is a new pod |

A container that keeps exiting is not restarted at full speed forever. **The kubelet waits longer
each time** — ten seconds, then twenty, then forty, up to five minutes — and shows the pod as
`CrashLoopBackOff` while it waits. Lesson 40 reads that state as the symptom it is.

Note what the kubelet does *not* do: it never moves the pod to another node. A restart fixes a
process that died. It cannot fix a node that died, because the kubelet doing the restarting is on
that node.
