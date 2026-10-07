---
title: One line of arithmetic, every fifteen seconds
version: 1
---

The autoscaler reads its numbers from metrics-server, which a kind cluster does not have, so this
lesson starts with `./up.sh` and installs it as lesson 21 did:

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
```

Then the shop, with one replica and a CPU request of 200m. **The request matters more here than anywhere
else**, because the autoscaler measures each pod as a percentage of what it requested:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
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
            cpu: 200m
            memory: 32Mi
          limits:
            memory: 64Mi
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
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shop
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  minReplicas: 1
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
```

Read the autoscaler as a sentence: keep `shop` between one and six replicas, aiming for an average CPU
use of 50% of the request, which here is 100m per pod. The `behavior` block is the next section's
subject.

```
ana@laptop:~/shop$ kubectl apply -f hpa.yaml
horizontalpodautoscaler.autoscaling/shop created
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 0%/50%   1         6         1          60s
```

`cpu: 0%/50%`: nobody is calling the shop, so the one replica is idle and the autoscaler leaves it
alone. It reads its numbers from metrics-server, installed as in lesson 21.

## Under load

A busybox pod now runs four loops at once, each asking the shop for 300 milliseconds of work at a
time, for two and a half minutes. The first line starts the pod; the second starts the loops and holds
the terminal until they end, so run it in a second terminal:

```sh
kubectl run load --image=busybox:1.37 --restart=Never --command -- sleep 3600
kubectl exec load -- sh -c 'for n in 1 2 3 4; do (end=$(($(date +%s)+150)); while [ $(date +%s) -lt $end ]; do wget -qO- "shop/work?ms=300" >/dev/null; done) & done; wait'
```

Forty-five seconds in, and again a minute later:

```
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 604%/50%   1         6         6          106s
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 174%/50%   1         6         6          2m46s
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS   AGE
shop-5b54594cd-8776z   1/1     Running   0          76s
shop-5b54594cd-96cg9   1/1     Running   0          2m47s
shop-5b54594cd-bxz6q   1/1     Running   0          76s
shop-5b54594cd-lzslv   1/1     Running   0          91s
shop-5b54594cd-prnp2   1/1     Running   0          76s
shop-5b54594cd-v2tfx   1/1     Running   0          76s
```

**604% against a target of 50, and six replicas.** The formula the controller applies is

`desired = ceil(current replicas × current utilisation ÷ target utilisation)`

and applied to that reading with a single replica it gives `ceil(1 × 604 ÷ 50) = 13`, far past
`maxReplicas`, which caps it at 6. With six copies
sharing the work, the average fell to 174%: still above the target, but the autoscaler may not go
higher, so it stays at its ceiling. A real ceiling is a decision about cost and about what the
database behind the shop can take, and hitting it is something to alert on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A loop of four steps. metrics-server reports each pod's CPU. The HPA divides it by the pod's request to get utilisation, and averages it. It computes desired replicas as current replicas times current utilisation over target, rounded up, and clamps the result between minReplicas and maxReplicas. It writes the number into the Deployment's replicas, and the Deployment adds or removes pods. Then the loop starts again fifteen seconds later.\"><defs><marker id=\"hpa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hpa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">metrics-server</text><text x=\"105.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each pod's CPU</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HPA</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">÷ request = utilisation</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Deployment</text><text x=\"615.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">spec.replicas</text><rect x=\"170\" y=\"150\" width=\"380\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ceil(replicas × utilisation ÷ target)</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minReplicas ≤ n ≤ maxReplicas</text><path d=\"M192 58 L268 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-paper-dim)\"></path><path d=\"M360 88 L360 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-amber)\"></path><path d=\"M552 178 L615 178 L615 88\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-amber)\"></path><text x=\"624\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">replicas</text><path d=\"M530 44 L500 14 L105 14 L105 28\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hpa-ah-paper-dim)\"></path><text x=\"300\" y=\"8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every 15 s</text></svg>", "caption": "The autoscaler never touches a pod. It changes one number on the Deployment and lets the Deployment do the rest."}
```

The autoscaler's events tell the story in order:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler -o custom-columns=REASON:.reason,MESSAGE:.message
REASON                         MESSAGE
FailedGetResourceMetric        failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
FailedComputeMetricsReplicas   invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
SuccessfulRescale              New size: 2; reason: cpu resource utilization (percentage of request) above target
SuccessfulRescale              New size: 6; reason: cpu resource utilization (percentage of request) above target
```

The first two lines are the minute after the autoscaler was created, before metrics-server had a
sample of the new pod. **Without a measurement it does nothing**, which is the safe failure. Then two
steps, to 2 and to 6: scaling up is also limited per period, by default to doubling or four pods every
fifteen seconds, whichever is more, so a sudden spike is met in steps.

A pod with no CPU request cannot be measured as a percentage, and the autoscaler refuses to scale on
it. That is one more reason, after lesson 19's, for always writing requests.
