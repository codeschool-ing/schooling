---
title: When the cluster is full, who goes first
version: 1
---

Lesson 19 left a pod `Pending` because no node had room, and the scheduler's message ended with
"preemption: … No preemption victims found". **Preemption is the scheduler making room for a pod by
evicting pods of lower priority**, and priority is set by a PriorityClass:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: checkout
value: 100000
description: "The path that takes customers' money."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch
value: 1000
description: "Reports and other work that can wait."
```

```
ana@laptop:~/shop$ kubectl apply -f priorities.yaml
priorityclass.scheduling.k8s.io/checkout created
priorityclass.scheduling.k8s.io/batch created
ana@laptop:~/shop$ kubectl get priorityclasses
NAME                      VALUE        GLOBAL-DEFAULT   AGE   PREEMPTIONPOLICY
batch                     1000         false            1s    PreemptLowerPriority
checkout                  100000       false            1s    PreemptLowerPriority
system-cluster-critical   2000000000   false            28s   PreemptLowerPriority
system-node-critical      2000001000   false            28s   PreemptLowerPriority
```

A class is a name for a number; higher wins. The two `system-` classes come with the cluster, for the
components it cannot run without, and are far above anything an application should use.

The batch work arrives first and fills the cluster: four copies at 1700m of CPU each, two per worker,
leaving each node a few hundred millicores free.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch
spec:
  replicas: 4
  selector:
    matchLabels:
      app: batch
  template:
    metadata:
      labels:
        app: batch
    spec:
      priorityClassName: batch
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
```

```
ana@laptop:~/shop$ kubectl apply -f batch.yaml
deployment.apps/batch created
ana@laptop:~/shop$ kubectl get pods -l app=batch -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
batch-777ccd8566-5bqqk   1/1     Running   0          0s    10.244.1.7   shop-worker2   <none>           <none>
batch-777ccd8566-d8gwj   1/1     Running   0          0s    10.244.2.7   shop-worker    <none>           <none>
batch-777ccd8566-rkg2t   1/1     Running   0          0s    10.244.2.6   shop-worker    <none>           <none>
batch-777ccd8566-tdrjj   1/1     Running   0          0s    10.244.1.8   shop-worker2   <none>           <none>
```

Then checkout, two copies of the same size and a hundred times the priority:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      priorityClassName: checkout
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
```

```
ana@laptop:~/shop$ kubectl apply -f checkout.yaml
deployment.apps/checkout created
ana@laptop:~/shop$ kubectl get pods -l "app in (batch,checkout)" -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,STATUS:.status.phase,NODE:.spec.nodeName
NAME                       PRIORITY   STATUS    NODE
batch-777ccd8566-9cv8t     1000       Pending   <none>
batch-777ccd8566-d8gwj     1000       Running   shop-worker
batch-777ccd8566-lshzm     1000       Pending   <none>
batch-777ccd8566-tdrjj     1000       Running   shop-worker2
checkout-6cfcc6c86-mk8tg   100000     Running   shop-worker2
checkout-6cfcc6c86-nftr2   100000     Running   shop-worker
```

**Both checkout copies are running, and two batch copies have become `Pending`.** Neither node had
1700m free, so for each checkout pod the scheduler looked for lower-priority pods whose removal would
make room, evicted one batch pod on each node, and placed checkout there. The batch Deployment
replaced its two pods, and the replacements wait, because nothing of lower priority is left to evict.
The events name the victims:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=Preempted -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message
OBJECT                   MESSAGE
batch-777ccd8566-5bqqk   Preempted by pod c8d36575-6d91-47f7-84b4-26934b3a478d on node shop-worker2
batch-777ccd8566-rkg2t   Preempted by pod d6296d9a-5d48-4906-8dde-c7c78b5db526 on node shop-worker
```

Preemption respects PodDisruptionBudgets where it can, but it will break one if nothing else frees
the room; a budget protects against maintenance, not against a more important pod.

**Three cautions.** A Deployment's pods are only as important as its class says, so a cluster where
every team gives itself the highest class has no priorities at all; administrators usually restrict
who may use the high classes. A class with `preemptionPolicy: Never` queues ahead of others but evicts
nobody, which suits work that is urgent but not worth killing anything for. And preemption frees room
as the scheduler counts it, in requests, so it is only as good as the requests are honest.
