---
title: A limit is a ceiling, and the two resources hit it differently
version: 1
---

A request decides where a pod goes. **A limit decides what happens to it once it is there**: the
kubelet hands it to the Linux kernel as a cgroup setting, and the kernel enforces it on every
scheduling tick and every allocation. CPU and memory are enforced in opposite ways, because they are
opposite kinds of resource.

## CPU: slowed down, never killed

Two copies of the shop, alike except for one line: `capped` has a CPU limit of 100m, and `free` has
none.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: capped
  labels:
    app: capped
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: free
  labels:
    app: free
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
```

The shop's `/work` endpoint spins for the number of milliseconds it is given and reports how many
loops it managed. The `probe` pod calls each copy at its pod address, looked up beforehand:

```
ana@laptop:~/shop$ kubectl apply -f cpu.yaml
pod/capped created
pod/free created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.2.6:8080/work?ms=1000'
worked 1000ms, 14556734 loops, on free
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.1.5:8080/work?ms=1000'
worked 1000ms, 1470592 loops, on capped
```

**The same second of wall time bought `free` 14,556,734 loops and `capped` 1,470,592, about a
tenth.** That is exactly what a 100m limit means: in every 100-millisecond period, the kernel lets the
container run for 10 milliseconds and then makes it wait. The request did not slow `free` down at all;
a request is a floor, and `free` could use whatever the node had spare.

CPU can be taken away and given back a millisecond later, so the kernel throttles and nothing breaks
except the time. A request that takes a hundred milliseconds unthrottled takes about a second under
this limit, which is why a CPU limit set too low shows up as latency, never as an error.

## Memory: killed

Memory cannot be paused and handed back. A process that holds memory over its limit can only lose
it by dying.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hungry
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        memory: 64Mi
      limits:
        memory: 64Mi
```

The shop's `/eat` endpoint allocates the number of megabytes it is given and keeps them:

```
ana@laptop:~/shop$ kubectl apply -f hungry.yaml
pod/hungry created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.1.6:8080/eat?mb=30'
holding 30 MiB on hungry
```

30 MiB, plus what the shop itself uses, fits under 64. Sixty more does not:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- -T 5 '10.244.1.6:8080/eat?mb=60'
wget: error getting response
command terminated with exit code 1
ana@laptop:~/shop$ kubectl get pod hungry
NAME     READY   STATUS    RESTARTS     AGE
hungry   1/1     Running   1 (5s ago)   6s
ana@laptop:~/shop$ kubectl get pod hungry -o jsonpath="{.status.containerStatuses[0].lastState.terminated}"; echo
{"containerID":"containerd://35cede72e8e5dded14a9b57c45e511a6f227bb42fd28fe7aac248a036968ceb0","exitCode":137,"finishedAt":"2026-10-06T17:48:38Z","reason":"OOMKilled","startedAt":"2026-10-06T17:48:38Z"}
```

**The request got no answer, because the process that would have answered was killed mid-way.** The
pod is still `Running`, with one restart five seconds ago: the kubelet started the container again,
as `restartPolicy: Always` says. The previous container's state is the evidence: `OOMKilled`, exit
code 137, which is 128 plus 9, the signal number of SIGKILL. The kernel's out-of-memory killer does
not ask politely, so nothing in the shop's own log mentions it.

| | CPU | memory |
|---|---|---|
| over the request | allowed, when the node has spare | allowed, when the node has spare |
| at the limit | throttled: the container waits | the container is killed (`OOMKilled`) |
| what you see | slower answers | restarts, exit code 137 |
