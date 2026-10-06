---
title: What a pod uses, against what it asked for
version: 1
---

Three copies of the shop, each asking for half a CPU and 256 MiB, which is the kind of number people
write when they have nothing to go on:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
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
        resources:
          requests:
            cpu: 500m
            memory: 256Mi
          limits:
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
```

After a minute, so that metrics-server has made a few rounds, `kubectl top` reads its figures:

```
ana@laptop:~/shop$ kubectl top nodes
NAME                 CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
shop-control-plane   143m         3%       615Mi           3%          
shop-worker          46m          1%       220Mi           1%          
shop-worker2         40m          1%       197Mi           1%          
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-c8d475877-qb528   1m           1Mi             
shop-c8d475877-t5vqk   0m           6Mi             
shop-c8d475877-zd49p   0m           1Mi             
```

**Usage is a measurement, and it changes from one minute to the next.** `CPU(cores)` is the average
over the kubelet's last sample window, in millicores; `MEMORY(bytes)` is the working set, the memory a
container is actually holding and cannot easily give back. The control-plane node uses the most because
the API server, etcd and the controllers run there. The shop, with nobody calling it, uses one
millicore at most and a few mebibytes.

## The gap

Set the requests beside those numbers:

```
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,CPU-REQUEST:.spec.containers[0].resources.requests.cpu,MEMORY-REQUEST:.spec.containers[0].resources.requests.memory
NAME                   CPU-REQUEST   MEMORY-REQUEST
shop-c8d475877-qb528   500m          256Mi
shop-c8d475877-t5vqk   500m          256Mi
shop-c8d475877-zd49p   500m          256Mi
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 6 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1300m (32%)  0 (0%)
  memory             832Mi (5%)   682Mi (4%)
  ephemeral-storage  0 (0%)       0 (0%)
```

**Each copy reserves 500m and uses about 1m; reserves 256 MiB and holds a few.** On `shop-worker`,
two copies account for 1000m of the 1300m requested, and the scheduler counts all of it as taken. A
cluster built for these requests needs nodes for 1.5 CPUs and 768 MiB that do nothing.

That waste is the most common cost in a Kubernetes cluster, and it is invisible from inside it:
nothing fails, nothing is slow, and the cloud bill shows only that the nodes were busy being reserved.
Lesson 46 puts a price on it.

But an idle measurement proves only that the shop was idle. The next section measures it working,
which is what a request has to cover.
