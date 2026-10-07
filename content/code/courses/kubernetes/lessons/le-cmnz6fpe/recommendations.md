---
title: What the recommender suggests
version: 1
---

**The Vertical Pod Autoscaler has three parts**: a recommender that watches usage and computes
requests, an updater that evicts pods whose requests are far from the recommendation, and an
admission controller that writes the recommended requests into new pods. This lab installs only the
recommender, with the project's CRDs and RBAC (`lab.sh vpa`), because reading recommendations is the
safe first step, and it is what `updateMode: "Off"` asks for anyway.

The shop, with requests that are wrong on purpose, far less CPU than it uses under load and far more
memory than it uses:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 2
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
            cpu: 50m
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

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: shop
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  updatePolicy:
    updateMode: "Off"
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml -f vpa.yaml
deployment.apps/shop created
service/shop created
verticalpodautoscaler.autoscaling.k8s.io/shop created
```

A busybox pod kept the shop busy, and four minutes later:

```
ana@laptop:~/shop$ kubectl get vpa shop
NAME   MODE   CPU    MEM     PROVIDED   AGE
shop   Off    671m   250Mi   True       4m1s
ana@laptop:~/shop$ kubectl get vpa shop -o jsonpath='{range .status.recommendation.containerRecommendations[*]}{.containerName}: lower {.lowerBound} target {.target} upper {.upperBound}{"\n"}{end}'
shop: lower {"cpu":"181m","memory":"250Mi"} target {"cpu":"671m","memory":"250Mi"} upper {"cpu":"496178m","memory":"8503807692"}
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-8c87b866c-b4f85   446m         5Mi             
shop-8c87b866c-tsbst   497m         6Mi             
```

**The target is 671m of CPU and 250Mi of memory**, against 50m and 256Mi requested. The CPU figure
follows the measurement: the two pods were using about 450m to 500m each, and the recommender adds a
margin. The memory figure is a floor, not a measurement: the shop uses a few mebibytes, but the
recommender never suggests less than 250Mi unless it is told to, so on memory it says almost nothing
here. **Read a recommendation against the usage before applying it.**

The bounds say how sure it is. After four minutes the upper bound is enormous, because the
recommender has little history and widens its range to match; it narrows over days. That is the same
point lesson 21 made about one reading of `kubectl top`, built into the numbers.

| `updateMode` | what the VPA does |
|---|---|
| `Off` | recommends only, as here |
| `Initial` | sets requests on new pods, never touches running ones |
| `Recreate` | evicts pods to give them new requests |
| `InPlaceOrRecreate` | resizes pods in place where it can, evicts where it cannot |

**Do not let a VPA and an HPA both act on CPU for the same Deployment.** The VPA raises requests
because usage is high, the HPA sees utilisation fall as a percentage of the larger request and
removes pods, and each undoes the other.
