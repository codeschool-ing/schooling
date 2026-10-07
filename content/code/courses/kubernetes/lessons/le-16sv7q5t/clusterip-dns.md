---
title: One address, one name, and a list behind them
version: 1
---

**A Service is not a process and has no pod of its own.** It is an object with an address, a selector
and a port, and two things keep it true: a controller that keeps a list of the pods matching the
selector, and kube-proxy on every node, which turns the address into a route to one of them.

This lesson starts on lesson 8's cluster, with your machine's port 8080 on the nodes' port 30080, and
a busybox pod called `probe` to ask questions from inside:

```sh
./up.sh ports.yaml
kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600
```

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
        ports:
        - name: http
          containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - name: http
    port: 80
    targetPort: http
```

`targetPort: http` names the container's port rather than repeating `8080`; if the shop moves to
another port, only the container's port changes.

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl get service shop
NAME   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
shop   ClusterIP   10.96.250.86   <none>        80/TCP    1s
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop
NAME         ADDRESSTYPE   PORTS   ENDPOINTS                          AGE
shop-l5gb5   IPv4          8080    10.244.1.4,10.244.2.4,10.244.2.3   1s
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,IP:.status.podIP
NAME                    IP
shop-59d88b64fd-sw4tv   10.244.1.4
shop-59d88b64fd-t7pdd   10.244.2.3
shop-59d88b64fd-xp95g   10.244.2.4
```

The Service's address, `10.96.250.86`, comes from the cluster's service range and never changes while
the Service exists. **The list is an EndpointSlice**, kept by a controller: three addresses, which are
exactly the three pods' addresses, on port 8080. When a pod is replaced, its address leaves the slice
and the new one joins it; callers never see the change.

## The name

Every pod is given a resolver that knows the cluster's names:

```
ana@laptop:~/shop$ kubectl exec probe -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

`10.96.0.10` is CoreDNS, itself behind a Service. The `search` line is why a bare `shop` works: the
resolver tries `shop.default.svc.cluster.local` first, the pod's own namespace. **`ndots:5` makes the
resolver try those search domains for any name with fewer than five dots**, which is convenient
inside the cluster and the reason a lookup of an outside name costs several failed queries first.

```
ana@laptop:~/shop$ kubectl exec probe -- nslookup shop
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	shop.default.svc.cluster.local
Address: 10.96.250.86

** server can't find shop.svc.cluster.local: NXDOMAIN

** server can't find shop.cluster.local: NXDOMAIN

** server can't find shop.svc.cluster.local: NXDOMAIN

** server can't find shop.cluster.local: NXDOMAIN


command terminated with exit code 1
```

The answer that matters is the one with a name, `shop.default.svc.cluster.local` at `10.96.250.86`.
busybox's `nslookup` also prints every search domain it tried that had no such name, and exits with
an error because some of them failed; a program's resolver stops at the first answer. A Service in
another namespace is reached as `shop.other-namespace`, which the second search domain completes.

## Spreading the requests

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"
shop 1.0 on shop-59d88b64fd-sw4tv
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-sw4tv
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-xp95g
shop 1.0 on shop-59d88b64fd-sw4tv
```

Six requests, answered by two of the three pods. kube-proxy picks a pod at random for each new
connection, so six is too few to look even; lesson 17 counts three hundred.

## A Service with nobody behind it

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=0
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get endpointslices -l kubernetes.io/service-name=shop
NAME         ADDRESSTYPE   PORTS     ENDPOINTS   AGE
shop-l5gb5   IPv4          <unset>   <unset>     6s
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- -T 3 shop
wget: can't connect to remote host (10.96.250.86): Connection refused
command terminated with exit code 1
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=3
deployment.apps/shop scaled
```

**With no pods, the slice is empty and the address refuses connections.** The Service still exists,
its name still resolves, and a caller gets `Connection refused` immediately rather than waiting. That
is the symptom to recognise when a Service's selector matches nothing because of a typo in a label:
the Service looks fine, and its endpoint list is empty.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Three nested boxes. The innermost, ClusterIP, holds an address from the service range and the list of pods behind it. Around it, NodePort adds one port on every node. Around that, LoadBalancer adds an address of its own, provided by a cloud or by cloud-provider-kind. Arrows show where a caller enters each one: a pod enters ClusterIP, anything that reaches a node enters NodePort, the internet enters LoadBalancer.\"><defs><marker id=\"svc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"svc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"svc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"480\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoadBalancer</text><text x=\"240\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ an address of its own, from the provider</text><rect x=\"240\" y=\"70\" width=\"440\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodePort</text><text x=\"260\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+ one port on every node, 30000 to 32767</text><rect x=\"260\" y=\"124\" width=\"400\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ClusterIP</text><text x=\"280\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an address only the cluster knows</text><text x=\"280\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the pods in the EndpointSlice</text><rect x=\"500\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"550\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"600\" y=\"196\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the internet</text><path d=\"M204 40 L236 40\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-amber)\"></path><text x=\"200\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">anything that reaches a node</text><path d=\"M204 94 L256 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-phosphor)\"></path><text x=\"200\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a pod</text><path d=\"M204 148 L276 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#svc-ah-paper-dim)\"></path></svg>", "caption": "Each type is the one inside it plus one more way in. A LoadBalancer Service still has a NodePort and a ClusterIP."}
```
