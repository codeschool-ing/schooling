---
title: A slow start, and the probe that protects it
version: 1
---

Some programs take a long time to start: a JVM warming up, a cache loading from disk, a migration
checked at boot. **A liveness probe cannot tell "still starting" from "stuck"**, and it starts asking as
soon as the container does. The shop's `STARTUP_DELAY` makes it wait thirty seconds before it listens,
and this pod has only a liveness probe:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
```

```
ana@laptop:~/shop$ kubectl apply -f slow.yaml
pod/slow created
ana@laptop:~/shop$ kubectl get pod slow
NAME   READY   STATUS    RESTARTS      AGE
slow   1/1     Running   3 (10s ago)   55s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=slow,reason=Killing -o custom-columns=MESSAGE:.message | head -n 2
MESSAGE
Container shop failed liveness probe, will be restarted
```

**Three restarts in fifty-five seconds, and it will never finish starting.** Every time, the probe
failed three times — fifteen seconds — while the shop was still in its thirty-second wait, and the
kubelet killed it. Left alone, the restarts would slow down into `CrashLoopBackOff` and the pod would
never serve. Notice also `1/1` in `READY`: with no readiness probe, a container counts as ready as soon
as its process starts, which is the first thing this lesson set out to fix.

The fix is not a longer liveness delay, which would also slow the detection of a real hang for the rest
of the pod's life. It is a third probe:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: slow-fixed
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 12
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
```

```
ana@laptop:~/shop$ kubectl delete pod slow --wait=false
pod "slow" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f slow-fixed.yaml
pod/slow-fixed created
ana@laptop:~/shop$ kubectl get pod slow-fixed
NAME         READY   STATUS    RESTARTS   AGE
slow-fixed   1/1     Running   0          50s
```

**No restarts.** A startup probe runs first, and while it runs the other two wait. It allows twelve
failures five seconds apart, a full minute to start; the first success hands over to the liveness
probe, which then checks every five seconds with its strict threshold, exactly as before.

| probe | asks | on failure | while it runs |
|---|---|---|---|
| startup | has the program finished starting? | after `failureThreshold`, the container is restarted | liveness and readiness wait |
| readiness | should it get traffic now? | taken out of the Service's endpoints; nothing else | — |
| liveness | is the process worth keeping? | the container is restarted | — |

All three can ask over HTTP, as here, or open a TCP port, run a command inside the container, or call
gRPC's health service. Lesson 35 relies on readiness to keep a rolling update from sending traffic to a
copy that is not ready.
