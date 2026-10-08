---
title: The pod that is still being sent requests
version: 1
---

When the controller removes an old pod, two things start **at the same moment** and nothing orders
them. The kubelet sends the container `SIGTERM`. The endpoint controller takes the pod out of the
Service, and every node's kube-proxy then rewrites its rules. The second takes longer. In between, a
node can still send a new connection to a process that has already stopped listening.

The shop handles `SIGTERM` politely: it stops accepting connections and finishes the requests it has.
That is exactly what makes the gap visible. A connection that arrives after that point is **refused**,
and BusyBox's `wget` says so in those words.

The usual fix is to make the pod wait before it hears the signal. A `preStop` hook runs first, and
`SIGTERM` is only sent once it ends; the `sleep` action needs no shell in the image:

```yaml
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: shop
        lifecycle:
          preStop:
            sleep:
              seconds: 10
```

`terminationGracePeriodSeconds` is the whole budget, hook included. After thirty seconds the container
is killed whatever it is doing, so the sleep has to leave time for the shutdown after it. Then the same
count, through an update to `2.0`:

```
ana@laptop:~/shop$ kubectl patch deployment shop --patch-file graceful.yaml
deployment.apps/shop patched
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- -T 2 shop || echo FAILED; sleep 0.1; done" | cut -d" " -f1,2 | sort | uniq -c
wget: download timed out
      1 FAILED
     28 shop 1.1
    271 shop 2.0
ana@laptop:~/shop$ kubectl set image deployment/shop shop=shop:2.0
deployment.apps/shop image updated
```

**One failure again, and again a timeout.** Read the error before the count. A refused connection is
the race above; a timeout is something else, a packet that got no answer at all. Neither run had a
refusal, so on the machine this was recorded on the race did not show, and the timeout that remained has a cause this lesson
did not find. The `preStop` is still worth keeping, because the race is real wherever kube-proxy is
slower than here. What the count says is narrower: it did not take this run to zero.

That is the honest state of most rolling updates. They are **nearly** free, and the client that cannot
lose a single request retries it, since an idempotent `GET` repeated once costs nothing.
