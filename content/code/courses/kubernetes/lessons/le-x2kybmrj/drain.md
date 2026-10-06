---
title: Draining a node without breaking the application
version: 1
---

Nodes need maintenance: a kernel update, a new Kubernetes version, a machine being retired. **`kubectl
drain` empties a node politely**: it marks it unschedulable, then evicts its pods one by one through
the API, and each eviction asks first whether the application can afford to lose that pod.

The application answers through a PodDisruptionBudget:

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
      containers:
      - name: shop
        image: shop:1.0
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: shop
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: shop
```

Four copies, and the budget says at least three must be available at any moment. So voluntary
disruptions may take one copy at a time:

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
poddisruptionbudget.policy/shop created
ana@laptop:~/shop$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   3               N/A               1                     1s
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-56smx   1/1     Running   0          1s    10.244.3.3   shop-worker    <none>           <none>
shop-774b84ff8c-6mpgk   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
shop-774b84ff8c-cqttc   1/1     Running   0          1s    10.244.3.4   shop-worker    <none>           <none>
shop-774b84ff8c-gwndr   1/1     Running   0          1s    10.244.1.5   shop-worker2   <none>           <none>
```

`ALLOWED DISRUPTIONS 1`, and two of the four copies are on `shop-worker`. Now the drain:

```
ana@laptop:~/shop$ kubectl drain shop-worker --ignore-daemonsets --delete-emptydir-data --timeout=60s
node/shop-worker cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-sn4jp, kube-system/kube-proxy-xwlzs
evicting pod kube-system/coredns-856dd496c5-jjsm5
evicting pod default/shop-774b84ff8c-cqttc
evicting pod default/shop-774b84ff8c-56smx
error when evicting pods/"shop-774b84ff8c-cqttc" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/shop-774b84ff8c-56smx evicted
evicting pod default/shop-774b84ff8c-cqttc
pod/coredns-856dd496c5-jjsm5 evicted
pod/shop-774b84ff8c-cqttc evicted
node/shop-worker drained
```

Read it in order:

1. **`cordoned`**: the node is marked unschedulable, so nothing new lands on it.
2. DaemonSet pods are left alone, because their controller would put them straight back; that is
   what `--ignore-daemonsets` acknowledges. `--delete-emptydir-data` acknowledges that pods with an
   `emptyDir` lose it.
3. The first shop pod is evicted. **The second eviction is refused**: "would violate the pod's
   disruption budget", because with one copy gone and its replacement not yet ready, only three
   remain. kubectl retries after five seconds.
4. By then the replacement is ready, the budget allows another, and the second pod goes.

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-6mpgk   1/1     Running   0          7s    10.244.1.4   shop-worker2   <none>           <none>
shop-774b84ff8c-gwndr   1/1     Running   0          7s    10.244.1.5   shop-worker2   <none>           <none>
shop-774b84ff8c-jt4mc   1/1     Running   0          6s    10.244.1.6   shop-worker2   <none>           <none>
shop-774b84ff8c-qk7gn   1/1     Running   0          1s    10.244.1.7   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get node shop-worker
NAME          STATUS                     ROLES    AGE   VERSION
shop-worker   Ready,SchedulingDisabled   <none>   59s   v1.37.0
ana@laptop:~/shop$ kubectl uncordon shop-worker
node/shop-worker uncordoned
```

All four copies on `shop-worker2`, never fewer than three serving. The node stays `SchedulingDisabled`
until `uncordon` gives it back. The pods do not move back on their own; they stay where they are until
something replaces them, and lesson 31's spread constraints are what a rollout would use to even them
out again.

**A budget only governs voluntary disruptions**: drains, and the cluster autoscaler of lesson 34
removing a node. It cannot stop a node from failing, which is the next section, and it can block
maintenance forever if it is set to allow no disruptions at all, such as `minAvailable` equal to the
replica count.
