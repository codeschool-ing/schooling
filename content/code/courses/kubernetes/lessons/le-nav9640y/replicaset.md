---
title: A ReplicaSet counts labels
version: 1
---

**The intuitive picture is that a ReplicaSet owns a list of pods.** It does not hold a list at all.
It holds a number, a selector and a pod template, and its controller asks the API server one
question over and over: how many running pods match this selector? Fewer than the number, it makes
pods from the template; more, it deletes some. Everything below follows from that.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop$ kubectl apply -f web.yaml
deployment.apps/web created
ana@laptop:~/shop$ kubectl get replicasets
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   3         3         3       1s
ana@laptop:~/shop$ kubectl get replicaset -l app=web -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,SELECTOR:.spec.selector.matchLabels
NAME             OWNER        SELECTOR
web-768c88b7c7   Deployment   map[app:web pod-template-hash:768c88b7c7]
```

The Deployment made one ReplicaSet, `web-768c88b7c7`, and is recorded as its owner. Its selector is
the Deployment's `app: web` plus `pod-template-hash: 768c88b7c7`, a label the Deployment adds so
that this ReplicaSet counts only pods made from this exact template.

## A pod deleted is a pod replaced

```
ana@laptop:~/shop$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-5dbxj   1/1     Running   0          1s
web-768c88b7c7-vdxt7   1/1     Running   0          1s
web-768c88b7c7-wbwkb   1/1     Running   0          1s
ana@laptop:~/shop$ kubectl delete pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2)
pod "web-768c88b7c7-5dbxj" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-5xvw2   1/1     Running   0          2s
web-768c88b7c7-vdxt7   1/1     Running   0          3s
web-768c88b7c7-wbwkb   1/1     Running   0          3s
```

`5dbxj` is gone and `5xvw2`, two seconds old, has taken its place. **Nobody restored the pod**: the
count dropped to two, the controller noticed, and it made a new pod from the template with a new
name and, as lesson 9 would show, a new address. A pod is cattle here, not a pet; what survives is
the number.

## A pod relabelled is a pod disowned

The selector is the whole membership rule, so changing a pod's label changes whose it is. Ana moves
one pod to `app=debug`:

```
ana@laptop:~/shop$ kubectl label pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2) app=debug --overwrite
pod/web-768c88b7c7-5xvw2 labeled
ana@laptop:~/shop$ kubectl get pods -L app
NAME                   READY   STATUS    RESTARTS   AGE   APP
web-768c88b7c7-5xvw2   1/1     Running   0          5s    debug
web-768c88b7c7-l7mxz   1/1     Running   0          3s    web
web-768c88b7c7-vdxt7   1/1     Running   0          6s    web
web-768c88b7c7-wbwkb   1/1     Running   0          6s    web
ana@laptop:~/shop$ kubectl get replicaset -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   3         3         3       6s
```

**Four pods now, and the ReplicaSet still reports three.** `5xvw2` keeps running, untouched, but it
no longer answers the selector, so it no longer counts, and the controller made `l7mxz` to bring the
number back to three. The relabelled pod is an orphan: no Service selecting `app: web` sends it
traffic, nothing will replace it if it dies, and nothing will delete it either. **That is a useful
trick in an incident** — take a misbehaving pod out of rotation without killing it, so its state is
still there to inspect — and a hazard when it happens by accident. An edited label in a
template can strand a fleet of pods that keep running and keep costing money.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The Deployment web owns two ReplicaSets, one per template: web-768c88b7c7 for shop:1.0 wants 0 pods, and web-798bdd9498 for shop:1.1 wants 2. Each ReplicaSet counts the pods whose labels match its selector, app=web plus its own pod-template-hash. A pod relabelled app=debug matches neither and is counted by nobody.\"><defs><marker id=\"cnt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"cnt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"16\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web</text><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Deployment</text><rect x=\"40\" y=\"100\" width=\"280\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"180.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web-768c88b7c7</text><text x=\"180.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">template shop:1.0 · wants 0</text><rect x=\"400\" y=\"100\" width=\"280\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web-798bdd9498</text><text x=\"540.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">template shop:1.1 · wants 2</text><path d=\"M320 60 L200 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-paper-dim)\"></path><path d=\"M400 60 L520 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-paper-dim)\"></path><text x=\"396\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">counts pods labelled</text><text x=\"396\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod-template-hash=798bdd9498</text><rect x=\"410\" y=\"210\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nkhm8</text><text x=\"475.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop:1.1</text><path d=\"M540 162 L475 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-phosphor)\"></path><rect x=\"550\" y=\"210\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rx9tr</text><text x=\"615.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop:1.1</text><path d=\"M540 162 L615 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cnt-ah-phosphor)\"></path><rect x=\"60\" y=\"210\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5xvw2</text><text x=\"140.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app=debug</text><text x=\"140\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">counted by nobody</text></svg>", "caption": "A Deployment owns one ReplicaSet per version of its template, and each ReplicaSet counts labels. A pod outside every selector keeps running and belongs to nobody."}
```
