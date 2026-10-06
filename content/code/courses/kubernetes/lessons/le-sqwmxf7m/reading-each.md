---
title: Pending, misconfigured, and running but not ready
version: 1
---

## No node will take it

A pod that is `Pending` has no node, so it has no container, no logs and no kubelet events. **Only the
scheduler has spoken**, and its event says why:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=greedy -o custom-columns=REASON:.reason,MESSAGE:.message
REASON             MESSAGE
FailedScheduling   0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

Sixty-four CPUs requested, on nodes of four. Lesson 19 read this same message for a smaller mistake.

## The container cannot be configured

`unconfigured` reads its greeting from a ConfigMap that does not exist. The image is there and the
node is fine; the kubelet cannot build the container's environment, and says so in the pod's status:

```
ana@laptop:~/shop$ kubectl get pod unconfigured -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo
configmap "shop-settings" not found
ana@laptop:~/shop$ kubectl create configmap shop-settings --from-literal=greeting=hello
configmap/shop-settings created
ana@laptop:~/shop$ kubectl get pod unconfigured
NAME           READY   STATUS    RESTARTS   AGE
unconfigured   1/1     Running   0          76s
```

**The pod was not deleted or recreated.** It waited, and as soon as the ConfigMap existed, the kubelet
built the container and started it. Applying objects in the wrong order is the most common cause of
this status, and it fixes itself once the order is right.

## Running, and never ready

`never-ready` is `Running` with `0/1` ready. Nothing in the process is wrong: its readiness probe asks
port 9090, where nothing listens.

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=never-ready -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message
REASON      COUNT   MESSAGE
Scheduled   1       Successfully assigned default/never-ready to shop-worker
Pulled      1       Container image "shop:1.0" already present on machine and can be accessed by the pod
Created     1       Container created
Started     1       Container started
Unhealthy   25      Readiness probe failed: Get "http://10.244.2.4:9090/ready": dial tcp 10.244.2.4:9090: connect: connection refused
ana@laptop:~/shop$ kubectl describe pod never-ready | grep -E '^ +Ready|Readiness'
    Ready:          False
    Readiness:      http-get http://:9090/ready delay=0s timeout=1s period=3s successThreshold=1 failureThreshold=3
  Ready                       False 
  Warning  Unhealthy  8s (x25 over 75s)  kubelet            spec.containers{shop}: Readiness probe failed: Get "http://10.244.2.4:9090/ready": dial tcp 10.244.2.4:9090: connect: connection refused
```

**`Unhealthy`, 25 times, each with the exact request and the exact error**: the probe's URL and
`connection refused`. `kubectl describe` shows the probe's configuration beside it, and the mismatch
between the port the probe asks and the port the shop listens on is the whole diagnosis. The process
logs nothing, because a connection that is refused never reaches it.

| question | command |
|---|---|
| what is its status? | `kubectl get pods` |
| what did the scheduler and the kubelet say? | `kubectl describe pod NAME`, or `kubectl get events --field-selector involvedObject.name=NAME` |
| what did the process write? | `kubectl logs NAME`, and `--previous` after a restart |
| why is a container waiting? | `kubectl get pod NAME -o jsonpath='{.status.containerStatuses[0].state.waiting.message}'` |

Events are kept for an hour by default and then deleted, so a pod that failed overnight may have
none left to read. Keeping them longer is the job of the monitoring systems of lesson 41.
