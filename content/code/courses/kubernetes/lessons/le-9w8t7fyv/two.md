---
title: The same pods, two schedulers
version: 1
---

Two Deployments, identical except for one line: `packed` asks for `shop-scheduler`, and `spread` asks
for nothing, which means `default-scheduler`. Each pod requests half a CPU, so the choice of node is
the scheduler's to make:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread
spec:
  replicas: 4
  selector:
    matchLabels:
      app: spread
  template:
    metadata:
      labels:
        app: spread
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: packed
spec:
  replicas: 4
  selector:
    matchLabels:
      app: packed
  template:
    metadata:
      labels:
        app: packed
    spec:
      schedulerName: shop-scheduler
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
```

```
ana@laptop:~/shop$ kubectl apply -f two-ways.yaml
deployment.apps/spread created
deployment.apps/packed created
ana@laptop:~/shop$ kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.metadata.name
NAME                      NODE
packed-64d855c967-2wnpl   shop-worker2
packed-64d855c967-77rm5   shop-worker2
packed-64d855c967-fwq8l   shop-worker2
packed-64d855c967-rsdft   shop-worker2
spread-b88fc96d5-pl2cg    shop-worker2
spread-b88fc96d5-qtvnf    shop-worker2
spread-b88fc96d5-w7l86    shop-worker
spread-b88fc96d5-wx6v9    shop-worker
ana@laptop:~/shop$ kubectl get events --field-selector reason=Scheduled -o custom-columns=POD:.involvedObject.name,FROM:.reportingComponent,SOURCE:.source.component | sort | uniq | head -n 9
POD                       FROM                SOURCE
packed-64d855c967-2wnpl   shop-scheduler      <none>
packed-64d855c967-77rm5   shop-scheduler      <none>
packed-64d855c967-fwq8l   shop-scheduler      <none>
packed-64d855c967-rsdft   shop-scheduler      <none>
spread-b88fc96d5-pl2cg    default-scheduler   default-scheduler
spread-b88fc96d5-qtvnf    default-scheduler   default-scheduler
spread-b88fc96d5-w7l86    default-scheduler   default-scheduler
spread-b88fc96d5-wx6v9    default-scheduler   default-scheduler
```

**`spread` went two and two; `packed` went four to one node.** The events say who decided each one.
`FROM` is the event's reporting component, and it names the scheduler. The older `source` field is
filled by the cluster's scheduler and left empty by the second one, which is a reminder to read the
column that is there in both.

A pod no scheduler claims is the quieter case:

```
ana@laptop:~/shop$ kubectl run orphan --image=shop:1.0 --overrides='{"spec":{"schedulerName":"nobody"}}'
pod/orphan created
ana@laptop:~/shop$ kubectl get pod orphan
NAME     READY   STATUS    RESTARTS   AGE
orphan   0/1     Pending   0          10s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=orphan
No resources found in default namespace.
```

Pending, and **not one event**. When the default scheduler cannot place a pod it says why, in a
`FailedScheduling` event, as lesson 29 showed. Here nothing has even tried, so nothing writes
anything. A typo in `schedulerName`, or a second scheduler that has stopped, looks exactly like this:
a pod waiting in silence. The question to ask a Pending pod with no events is which scheduler it asked
for, and whether that scheduler is running.
