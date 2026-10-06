---
title: A request is a reservation
version: 1
---

Every node tells the scheduler how much it has to give away. **Allocatable is the node's capacity
minus what the kubelet keeps back for the operating system and itself**, and it is the number every
placement is measured against:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory
NAME                 CPU   MEMORY
shop-control-plane   4     16480968Ki
shop-worker          4     16480968Ki
shop-worker2         4     16480968Ki
```

Four CPUs and about 16 GiB of memory on each node. CPU is counted in millicores: `1500m` is one and a
half CPUs, `100m` is a tenth of one.

A request says how much of that a container needs reserved. The Deployment below asks for one and a
half CPUs per copy, five copies:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: big
spec:
  replicas: 5
  selector:
    matchLabels:
      app: big
  template:
    metadata:
      labels:
        app: big
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1500m"
            memory: 64Mi
```

```
ana@laptop:~/shop$ kubectl apply -f big.yaml
deployment.apps/big created
ana@laptop:~/shop$ kubectl get pods -l app=big -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
big-749579674d-ddttp   1/1     Running   0          10s   10.244.2.5   shop-worker    <none>           <none>
big-749579674d-fzpjd   1/1     Running   0          10s   10.244.1.3   shop-worker2   <none>           <none>
big-749579674d-gl76z   0/1     Pending   0          10s   <none>       <none>         <none>           <none>
big-749579674d-t9g9m   1/1     Running   0          10s   10.244.1.4   shop-worker2   <none>           <none>
big-749579674d-wtg9l   1/1     Running   0          10s   10.244.2.4   shop-worker    <none>           <none>
```

**Four ran and one stayed `Pending`.** The scheduler's event says why:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
```

The control-plane node has a taint that keeps ordinary pods off it (lesson 30 is about taints), and
the two workers each had "insufficient cpu". The preemption half of the message says that no running
pod could be evicted to make room, which lesson 31 explains. The node's own account shows the
arithmetic:

```
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 8 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                3200m (80%)  0 (0%)
  memory             248Mi (1%)   170Mi (1%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
```

`3200m (80%)`: two copies of `big` at 1500m each, plus 200m that pods the cluster runs for itself
had already requested: 100m for the network plugin and 100m for the copy of CoreDNS on this node. 800m was left, and the fifth copy needed 1500m.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two bars, one per worker node, each 4 CPUs wide. On shop-worker: 200m already requested by the node's own pods, then two pods of big at 1500m each, which leaves 800m free. shop-worker2 is the same. A fifth pod of big, asking for 1500m, is drawn beside them, Pending, because 800m is less than 1500m on both nodes.\"><defs><marker id=\"fit-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker</text><rect x=\"130\" y=\"40\" width=\"460.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"40\" width=\"23.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"153.0\" y=\"40\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"239.25\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"239.25\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><rect x=\"325.5\" y=\"40\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"411.75\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"411.75\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"544.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">800m free</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"130\" y=\"120\" width=\"460.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"120\" width=\"23.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"153.0\" y=\"120\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"239.25\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"239.25\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><rect x=\"325.5\" y=\"120\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"411.75\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"411.75\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"544.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">800m free</text><text x=\"141.5\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">system</text><rect x=\"620\" y=\"75\" width=\"84\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"662.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"662.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"662\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Pending</text><text x=\"662\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">needs 1500m</text><text x=\"130\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"590.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4000m</text><path d=\"M130 188 L590.0 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "The scheduler adds requests, not usage. Both nodes were nearly idle, and neither had 1500m left to promise."}
```

**The scheduler adds up requests, never usage.** The shop sat idle the whole time, using almost no
CPU, and the fifth pod still had nowhere to go. That is the deal a request makes: the pod is
guaranteed what it asked for, so the scheduler must never promise the same millicore twice. Asking
for too much wastes nodes, which lesson 21 measures. Asking for too little packs pods onto a node that
cannot run them all at full speed.

A pod with no request at all reserves nothing, and the scheduler can put it anywhere. That is
convenient and it is also how a node ends up running more than it can carry.
