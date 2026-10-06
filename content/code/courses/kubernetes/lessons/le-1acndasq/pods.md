---
title: Choosing nodes by the pods already on them
version: 1
---

Node rules look at the node. **Pod affinity and anti-affinity look at the pods already running there**,
which is how to say "not next to each other" and "next to that".

## Apart: anti-affinity

Three copies of the shop are three copies only if they are on different machines; three on one node
die together.

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
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: shop
        image: shop:1.0
```

Read the rule as a sentence: do not put this pod in a `topologyKey` domain that already holds a pod
matching `app: shop`. With `kubernetes.io/hostname` as the key, the domain is a single node.

```
ana@laptop:~/shop$ kubectl apply -f spread-out.yaml
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
shop-6c485b4895-2xds4   0/1     Pending   0          10s   <none>        <none>         <none>           <none>
shop-6c485b4895-ctzx7   1/1     Running   0          10s   10.244.2.3    shop-worker    <none>           <none>
shop-6c485b4895-x2l85   1/1     Running   0          10s   10.244.1.10   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match pod anti-affinity rules. preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
```

**One copy on each worker, and the third `Pending`.** Two nodes can take ordinary pods, the rule allows
one copy on each, and it is a requirement, so the third waits rather than doubling up. That is the
behaviour asked for and a trap at the same time: a cluster with fewer nodes than replicas cannot run
the Deployment in full. The preferred form,
`preferredDuringSchedulingIgnoredDuringExecution`, spreads when it can and doubles up when it must,
and lesson 31's topology spread constraints say the same thing with a number for how uneven is
acceptable.

With `topology.kubernetes.io/zone` as the key, the same rule puts each copy in a different zone, which
is what survives the loss of a data centre.

## Together: affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidekick
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sidekick
  template:
    metadata:
      labels:
        app: sidekick
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: box
        image: busybox:1.37
        command: ["sleep", "3600"]
```

`podAffinity` is the opposite sentence: put this pod in a domain that already holds a pod labelled
`app: shop`.

```
ana@laptop:~/shop$ kubectl apply -f next-to-shop.yaml
deployment.apps/sidekick created
ana@laptop:~/shop$ kubectl get pods -l "app in (shop,sidekick)" -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
NAME                        STATUS    NODE
shop-6c485b4895-2xds4       Pending   <none>
shop-6c485b4895-ctzx7       Running   shop-worker
shop-6c485b4895-x2l85       Running   shop-worker2
sidekick-64c4f9b8f4-lscdb   Running   shop-worker2
sidekick-64c4f9b8f4-tz5jf   Running   shop-worker
```

**Each sidekick landed on a node that has a shop pod.** Nothing tied the first sidekick to a
particular copy; the rule only asks for a node with one. A helper that must talk to its partner over
localhost belongs in the same pod instead, as a second container. Affinity is for things that only
benefit from being close, such as a cache next to the service that reads it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three nodes. shop-control-plane has a taint and takes no ordinary pods. shop-worker runs one shop pod and one sidekick. shop-worker2 runs one shop pod and one sidekick. The third shop pod is outside every node, Pending, because anti-affinity forbids a second shop pod on a node that already has one.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"102\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-control-plane</text><text x=\"102\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">taint: no ordinary pods</text><rect x=\"200\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"215\" y=\"56\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282.5\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"282.5\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><rect x=\"215\" y=\"112\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.5\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidekick</text><text x=\"282.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=sidekick</text><rect x=\"380\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"395\" y=\"56\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.5\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"462.5\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><rect x=\"395\" y=\"112\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462.5\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidekick</text><text x=\"462.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=sidekick</text><rect x=\"570\" y=\"56\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"635.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><text x=\"635\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Pending</text><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Pending: every node already has one</text></svg>", "caption": "Anti-affinity spread the shop one copy per node, and refused the third. Affinity then put each sidekick beside a copy."}
```

These rules cost the scheduler work. For every pod placed, it has to look at the pods on every
candidate node, so in a cluster of thousands of nodes, anti-affinity on everything slows scheduling
down; the topology spread constraints of lesson 31 are the cheaper tool when the goal is only to
spread.
