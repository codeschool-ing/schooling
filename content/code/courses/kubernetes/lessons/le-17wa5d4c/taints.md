---
title: A taint keeps pods out; a toleration lets one in
version: 1
---

Every capture so far has had a node that took no ordinary pods, and the scheduler's events kept
saying why: "1 node(s) had untolerated taint(s)". Here is that taint:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
NAME                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          <none>
shop-worker2         <none>
```

**A taint is a key, an optional value and an effect, set on a node.** kubeadm puts
`node-role.kubernetes.io/control-plane` on the control-plane node with the effect `NoSchedule`, so
that applications do not compete with the API server and etcd for the machine.

## Reserving a node

The reports team runs heavy queries and wants a machine of its own. The first half is a taint on that
machine:

```
ana@laptop:~/shop$ kubectl taint node shop-worker2 dedicated=reports:NoSchedule
node/shop-worker2 tainted
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=4
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-f7xmw   1/1     Running   0          1s    10.244.2.5   shop-worker   <none>           <none>
shop-774b84ff8c-krnt6   1/1     Running   0          1s    10.244.2.6   shop-worker   <none>           <none>
shop-774b84ff8c-wdkn8   1/1     Running   0          1s    10.244.2.3   shop-worker   <none>           <none>
shop-774b84ff8c-wv2nq   1/1     Running   0          1s    10.244.2.4   shop-worker   <none>           <none>
```

`dedicated=reports:NoSchedule` reads as key `dedicated`, value `reports`, effect `NoSchedule`. The
shop, created right after, has no toleration for it, and all four copies went to `shop-worker`.

The reports Deployment carries the second half:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reports
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reports
  template:
    metadata:
      labels:
        app: reports
    spec:
      tolerations:
      - key: dedicated
        operator: Equal
        value: reports
        effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: shop-worker2
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f reports.yaml
deployment.apps/reports created
ana@laptop:~/shop$ kubectl get pods -l app=reports -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
reports-b787947bc-vqqg5   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
reports-b787947bc-wf992   1/1     Running   0          1s    10.244.1.3   shop-worker2   <none>           <none>
```

**Both copies on `shop-worker2`, and the manifest needed two things to get them there.** The toleration
matches the taint (same key, value and effect), which makes the node acceptable. It does not make the
node preferred: without the `nodeSelector`, the scheduler could just as well put the reports on
`shop-worker`, among the shop's pods, and the reserved node would sit empty.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"shop-worker2 carries the taint dedicated=reports:NoSchedule. The four shop pods, with no toleration, are turned away and all land on shop-worker. The two reports pods carry a matching toleration, which lets them in, and a nodeSelector, which sends them there; both land on shop-worker2.\"><defs><marker id=\"taint-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><text x=\"684\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">dedicated=reports:NoSchedule</text><rect x=\"40\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"180\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"40\" y=\"120\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"180\" y=\"120\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><rect x=\"420\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">reports</text><rect x=\"560\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">reports</text><path d=\"M398 160 L322 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#taint-ah-amber)\"></path><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no toleration: kept out</text><text x=\"550\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">toleration: may enter</text><text x=\"550\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">nodeSelector: must go here</text><text x=\"550\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tolerations + nodeSelector</text></svg>", "caption": "The taint keeps others out; only the selector brings the reports in. A reserved node needs both halves."}
```

| piece | on | says |
|---|---|---|
| taint | the node | keep away, unless you tolerate this |
| toleration | the pod | I may go where this taint is |
| `nodeSelector` or node affinity | the pod | I must go where this label is |

Clouds use the same mechanism for machines that cost more: a node pool with GPUs is usually tainted,
so that only pods that asked for a GPU, and tolerate the taint, are placed on it.
