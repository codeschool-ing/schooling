---
title: Two questions with two different answers
version: 1
---

**Without probes, the kubelet knows exactly one thing about a container: whether its process is
running.** A shop that has lost its database connection, filled its thread pool or deadlocked is still
a running process, so it keeps its place in the Service and keeps receiving customers. Probes give the
kubelet a better question. The shop answers two of them: `/ready` and `/healthz`.

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n        ports:\n        - name: http\n          containerPort: 8080\n", "note": "**Two copies of the shop**, with the port named `http` so the probes below can refer to it by name."}, {"code": "        livenessProbe:\n          httpGet:\n            path: /healthz\n            port: http\n          periodSeconds: 5\n          failureThreshold: 3\n", "note": "**Liveness: is the process still worth keeping?** The kubelet asks `/healthz` every five seconds; three failures in a row and it restarts the container."}, {"code": "        readinessProbe:\n          httpGet:\n            path: /ready\n            port: http\n          periodSeconds: 5\n          failureThreshold: 1\n", "note": "**Readiness: should it get traffic right now?** One failure takes the pod out of the Service; one success puts it back. Nothing is restarted."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: shop\nspec:\n  selector:\n    app: shop\n  ports:\n  - port: 80\n    targetPort: http\n", "note": "**The Service the readiness answer feeds.** Its endpoint list marks each pod ready or not."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-5c9947569-bsfnw   1/1     Running   0          2s    10.244.2.3   shop-worker2   <none>           <none>
shop-5c9947569-zdchb   1/1     Running   0          1s    10.244.1.4   shop-worker    <none>           <none>
```

## Readiness: out of rotation, still running

The shop's `/drain` endpoint makes `/ready` start answering 503, which is what an application does when
it is about to shut down or has lost something it depends on. Ana drains the first pod:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- 10.244.2.3:8080/drain
draining
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS   AGE
shop-5c9947569-bsfnw   0/1     Running   0          10s
shop-5c9947569-zdchb   1/1     Running   0          9s
```

**`0/1` ready, still `Running`, zero restarts.** The readiness probe failed once and the kubelet marked
the pod not ready, which is all a readiness failure does. The Service's endpoint list now carries it
with `ready: false`:

```
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop -o custom-columns=ENDPOINTS:.endpoints[*].addresses[0],READY:.endpoints[*].conditions.ready
ENDPOINTS               READY
10.244.2.3,10.244.1.4   false,true
```

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
shop 1.0 on shop-5c9947569-zdchb
```

Six requests, all to the other pod. **The drained pod is out of rotation and untouched**, so it can
finish what it was doing, or wait for its database to come back and start answering `/ready` again, at
which point it rejoins without anybody acting.

## Liveness: a restart

`/break` makes `/healthz` answer 500, the shop's version of a process that is wedged:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- 10.244.2.3:8080/break
broken
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS      AGE
shop-5c9947569-bsfnw   1/1     Running   1 (14s ago)   35s
shop-5c9947569-zdchb   1/1     Running   0             34s
```

Three failures, five seconds apart, then a restart: **`RESTARTS 1`, and the pod is back to `1/1`**. The
restart cleared the drain as well, because a new process starts with neither flag set. The events say
which probe did what:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=shop-5c9947569-bsfnw,reason=Unhealthy -o custom-columns=MESSAGE:.message | tail -n 2
Readiness probe failed: HTTP probe failed with statuscode: 503
Liveness probe failed: HTTP probe failed with statuscode: 500
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=shop-5c9947569-bsfnw,reason=Killing -o custom-columns=MESSAGE:.message
MESSAGE
Container shop failed liveness probe, will be restarted
```

**A liveness probe is a loaded gun, so aim it carefully.** It should fail only when restarting the
process would help: a deadlock, a corrupted state that only a fresh start clears. If `/healthz` checked
the database instead, a database outage would restart every copy of the shop at once, over and over,
and turn a degraded service into a dead one. The database is a readiness question.
