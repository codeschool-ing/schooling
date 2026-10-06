---
title: Spreading copies with a bound on the difference
version: 1
---

Lesson 29's anti-affinity spread copies by forbidding two in one place. That works for three copies
and three nodes, and fails for six copies and two zones: the rule cannot be met, and the extra copies
wait. **A topology spread constraint asks for something weaker and more useful**: spread the pods
across the domains, and never let the busiest domain hold more than `maxSkew` pods above the
emptiest.

kind nodes have no zones, so the two workers were given the zone labels a cloud's nodes carry from
the start:

```
ana@laptop:~/shop$ kubectl get nodes -L topology.kubernetes.io/zone
NAME                 STATUS   ROLES           AGE   VERSION   ZONE
shop-control-plane   Ready    control-plane   26s   v1.37.0   
shop-worker          Ready    <none>          16s   v1.37.0   sa-east-1a
shop-worker2         Ready    <none>          16s   v1.37.0   sa-east-1b
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 6
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: shop
      containers:
      - name: shop
        image: shop:1.0
```

The constraint reads: over `topology.kubernetes.io/zone`, count the pods labelled `app: shop`, and do
not place a pod where that would make the difference between zones more than 1.

```
ana@laptop:~/shop$ kubectl apply -f spread.yaml
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.spec.nodeName
NAME                    NODE
shop-7c8fc6c98c-4nlqv   shop-worker
shop-7c8fc6c98c-bbwdf   shop-worker
shop-7c8fc6c98c-dd6wh   shop-worker
shop-7c8fc6c98c-dkmvx   shop-worker2
shop-7c8fc6c98c-qthb5   shop-worker2
shop-7c8fc6c98c-sxrh5   shop-worker2
```

**Three and three.** Anti-affinity with one copy per zone would have placed two and left four
waiting. Now one more:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=7
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NODE:.spec.nodeName --no-headers | sort | uniq -c
      3 shop-worker
      4 shop-worker2
```

Four and three, a difference of 1, which `maxSkew: 1` allows. An eighth copy would have to go to
`shop-worker`, the zone with three, and a ninth could then go to either.

| field | says |
|---|---|
| `topologyKey` | which node label defines a domain: a zone, a node, a rack |
| `maxSkew` | the largest difference allowed between the fullest and the emptiest domain |
| `whenUnsatisfiable` | `DoNotSchedule` waits, like a requirement; `ScheduleAnyway` places it and only prefers the even spread |
| `labelSelector` | which pods are counted |

**Two constraints are common together**: one over zones with `DoNotSchedule`, so that a zone failure
never takes more than its share, and one over `kubernetes.io/hostname` with `ScheduleAnyway`, so that
within a zone the copies also land on different nodes when they can. The constraint is checked when a
pod is placed, like every rule in lesson 29, so a cluster that lost a zone and got it back stays uneven
until something replaces pods.
