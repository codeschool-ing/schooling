---
title: Choosing nodes by their labels
version: 1
---

Every rule in this lesson works on labels, the same key-value pairs that Services use to find pods.
**Nodes carry labels too**: some are set by the kubelet (`kubernetes.io/hostname`, the operating
system, the architecture), some by a cloud (the zone, the machine type), and some by whoever runs the
cluster. Here one worker is labelled as having fast disks:

```
ana@laptop:~/shop$ kubectl label node shop-worker2 disk=ssd
node/shop-worker2 labeled
ana@laptop:~/shop$ kubectl get nodes -L disk
NAME                 STATUS   ROLES           AGE   VERSION   DISK
shop-control-plane   Ready    control-plane   34s   v1.37.0   
shop-worker          Ready    <none>          18s   v1.37.0   
shop-worker2         Ready    <none>          18s   v1.37.0   ssd
```

## A requirement: `nodeSelector`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search
spec:
  replicas: 3
  selector:
    matchLabels:
      app: search
  template:
    metadata:
      labels:
        app: search
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: shop
        image: shop:1.0
```

**`nodeSelector` is the plainest rule there is: every label listed must be on the node, or the pod
does not go there.**

```
ana@laptop:~/shop$ kubectl apply -f on-ssd.yaml
deployment.apps/search created
ana@laptop:~/shop$ kubectl get pods -l app=search -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
search-5f6cb89597-6djn8   1/1     Running   0          1s    10.244.1.3   shop-worker2   <none>           <none>
search-5f6cb89597-fc5xp   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
search-5f6cb89597-zwngc   1/1     Running   0          1s    10.244.1.5   shop-worker2   <none>           <none>
```

All three copies on `shop-worker2`, the only node with `disk=ssd`, even though `shop-worker` sat idle.
That is the point and the risk of a requirement: the scheduler obeys it even when it leaves a node
empty and puts every copy on one machine.

## A requirement nobody can meet

Change the selector to a label no node has:

```
ana@laptop:~/shop$ kubectl patch deployment search -p '{"spec":{"template":{"spec":{"nodeSelector":{"disk":"nvme"}}}}}'
deployment.apps/search patched
ana@laptop:~/shop$ kubectl get pods -l app=search
NAME                      READY   STATUS    RESTARTS   AGE
search-5f6cb89597-6djn8   1/1     Running   0          9s
search-5f6cb89597-fc5xp   1/1     Running   0          9s
search-5f6cb89597-zwngc   1/1     Running   0          9s
search-646fd449f9-zs8c5   0/1     Pending   0          8s
```

**The new pod waits in `Pending`, and the three old ones keep running.** The Deployment's rollout
creates a new pod before removing an old one, so a template nobody can place stops the rollout at its
first step, and the old version goes on serving; lesson 35 is about that behaviour. The scheduler's
event says what is missing:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

"Didn't match Pod's node affinity/selector" on both workers, and the control-plane node excluded by
its taint, which lesson 30 explains. A typo in a label is enough to produce exactly this.

## A preference

Node affinity says the same things in a longer form, and adds what a selector cannot: operators such
as `In`, `NotIn` and `Exists`, and preferences.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
spec:
  replicas: 4
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: disk
                operator: In
                values: ["nvme", "ssd"]
      containers:
      - name: shop
        image: shop:1.0
```

`preferredDuringSchedulingIgnoredDuringExecution` is a wish with a weight from 1 to 100: nodes that
match get extra points in the scheduler's scoring, and nodes that do not are still allowed.

```
ana@laptop:~/shop$ kubectl apply -f prefer-ssd.yaml
deployment.apps/cache created
ana@laptop:~/shop$ kubectl get pods -l app=cache -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
cache-66f4c4dfc4-dqrf2   1/1     Running   0          1s    10.244.1.6   shop-worker2   <none>           <none>
cache-66f4c4dfc4-gx86n   1/1     Running   0          1s    10.244.1.9   shop-worker2   <none>           <none>
cache-66f4c4dfc4-hml4x   1/1     Running   0          1s    10.244.1.8   shop-worker2   <none>           <none>
cache-66f4c4dfc4-zjvdn   1/1     Running   0          1s    10.244.1.7   shop-worker2   <none>           <none>
```

All four on `shop-worker2`. **A weight of 100 is a strong wish**, enough here to beat the scheduler's
own habit of spreading pods out, because the node had room for all four. Had it been full, the rest
would have gone to `shop-worker`, which a requirement would never allow. The long names say one more
thing: `IgnoredDuringExecution` means the rules are checked when a pod is placed and never again, so
removing the label later moves nothing.

| rule | kind | if no node matches |
|---|---|---|
| `nodeSelector` | requirement | the pod stays `Pending` |
| `requiredDuringScheduling…` node affinity | requirement, with operators | the pod stays `Pending` |
| `preferredDuringScheduling…` node affinity | preference, weighted | the pod goes elsewhere |
