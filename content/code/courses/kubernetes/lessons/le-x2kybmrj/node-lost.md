---
title: A node that disappears
version: 1
---

Nobody drains a node that loses power. **The cluster has to notice the silence, and then decide the
pods are gone**, and both steps take time on purpose: a node that misses a few heartbeats because of a
network blip should not have its pods replaced and then come back to find duplicates.

The shop is redeployed with the budget removed and one change, a shorter toleration for the taints of
lesson 30, so that the wait fits in a capture:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 4
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      tolerations:
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f shop-fast.yaml
deployment.apps/shop configured
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS      RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-64987c6d69-669wq   1/1     Running     0          0s    10.244.1.9   shop-worker2   <none>           <none>
shop-64987c6d69-gbkdv   1/1     Running     0          1s    10.244.3.5   shop-worker    <none>           <none>
shop-64987c6d69-sjr6p   1/1     Running     0          1s    10.244.3.6   shop-worker    <none>           <none>
shop-64987c6d69-slj6t   1/1     Running     0          1s    10.244.1.8   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   0/1     Completed   0          9s    10.244.1.5   shop-worker2   <none>           <none>
```

Two copies on each worker. The pod marked `Completed` is an old copy from before the change, which
exited cleanly when told to stop and is about to be cleaned up. Now `shop-worker2` is switched off,
which for a kind node means stopping its container, and fifty seconds later:

```
ana@laptop:~/shop$ docker stop shop-worker2
shop-worker2
ana@laptop:~/shop$ kubectl get node shop-worker2
NAME           STATUS     ROLES    AGE    VERSION
shop-worker2   NotReady   <none>   117s   v1.37.0
ana@laptop:~/shop$ kubectl get node shop-worker2 -o jsonpath="{.spec.taints[*].key}"; echo
node.kubernetes.io/unreachable node.kubernetes.io/unreachable
```

**`NotReady`, and two taints with the same key.** The node controller saw no heartbeat for longer than
its grace period and tainted the node `unreachable`, once with `NoSchedule` and once with `NoExecute`.
The default toleration of every pod lets it stay five minutes; this Deployment's lets it stay thirty
seconds. Forty-five seconds later:

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS        RESTARTS   AGE    IP           NODE           NOMINATED NODE   READINESS GATES
shop-64987c6d69-669wq   1/1     Terminating   0          101s   10.244.1.9   shop-worker2   <none>           <none>
shop-64987c6d69-f8tkc   1/1     Running       0          20s    10.244.3.7   shop-worker    <none>           <none>
shop-64987c6d69-gbkdv   1/1     Running       0          102s   10.244.3.5   shop-worker    <none>           <none>
shop-64987c6d69-pmbvk   1/1     Running       0          20s    10.244.3.8   shop-worker    <none>           <none>
shop-64987c6d69-sjr6p   1/1     Running       0          102s   10.244.3.6   shop-worker    <none>           <none>
shop-64987c6d69-slj6t   1/1     Terminating   0          102s   10.244.1.8   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   0/1     Completed     0          110s   10.244.1.5   shop-worker2   <none>           <none>
```

**Two new copies on `shop-worker`, twenty seconds old, and the shop back to four.** The two copies on
the lost node are `Terminating`, and they will stay that way: the deletion waits for the kubelet to
confirm the containers stopped, and that kubelet is not answering. If the machine never returns, an
operator deletes the Node object, and the pods go with it.

That is the whole cost of losing a machine: the grace period to notice, the toleration to decide, and
the time to start a replacement. **With the defaults, close to six minutes during which those
copies serve nobody**, which is why an application that matters runs enough copies, spread across
nodes and zones as lessons 29 and 31 showed, to carry the load without them.

| event | what moves the pods | can a budget hold it back? |
|---|---|---|
| node pressure | the kubelet evicts | no |
| `kubectl drain` | the Eviction API, one by one | yes |
| node lost | the node controller, after `tolerationSeconds` | no |
