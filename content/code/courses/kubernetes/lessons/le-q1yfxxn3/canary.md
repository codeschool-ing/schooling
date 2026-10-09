---
title: A canary is two Deployments and a weight
version: 1
---

The router in this lesson is lesson 16's: its cluster, the Gateway API's types, Traefik from its
`traefik.yaml`, and a Gateway called `public`, written here in a shorter form than lesson 16 used.

`gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata: {name: traefik}
spec: {controllerName: traefik.io/gateway-controller}
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: public}
spec:
  gatewayClassName: traefik
  listeners: [{name: web, protocol: HTTP, port: 8000, allowedRoutes: {namespaces: {from: Same}}}]
```

```sh
./up.sh ports.yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
kubectl apply -f traefik.yaml
kubectl -n traefik rollout status deployment/traefik
kubectl apply -f gateway.yaml
```

**A canary needs the two versions to be separate things the router can tell apart.** Here that is two
Deployments, three copies of 1.0 and one of 1.1, each with a Service of its own. Both carry
`app: shop`, and a second label, `track`, says which is which:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-stable
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
      track: stable
  template:
    metadata:
      labels:
        app: shop
        track: stable
    spec:
      containers:
      - name: shop
        image: shop:1.0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
      track: canary
  template:
    metadata:
      labels:
        app: shop
        track: canary
    spec:
      containers:
      - name: shop
        image: shop:1.1
---
apiVersion: v1
kind: Service
metadata:
  name: shop-stable
spec:
  selector:
    app: shop
    track: stable
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shop-canary
spec:
  selector:
    app: shop
    track: canary
  ports:
  - port: 80
    targetPort: 8080
```

```
ana@laptop:~/shop$ kubectl apply -f versions.yaml
deployment.apps/shop-stable created
deployment.apps/shop-canary created
service/shop-stable created
service/shop-canary created
ana@laptop:~/shop$ kubectl get pods -l app=shop -L track
NAME                           READY   STATUS    RESTARTS   AGE   TRACK
shop-canary-5579dbf66c-swxxp   1/1     Running   0          1s    canary
shop-stable-6fd5d87c47-8r22q   1/1     Running   0          1s    stable
shop-stable-6fd5d87c47-fwkbt   1/1     Running   0          1s    stable
shop-stable-6fd5d87c47-w9dfj   1/1     Running   0          1s    stable
```

The router is Traefik behind the Gateway API, installed as in lesson 16, with the same Gateway called
`public`. The route lists both Services and gives each a weight:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
spec:
  parentRefs:
  - name: public
  hostnames:
  - shop.example.test
  rules:
  - backendRefs:
    - name: shop-stable
      port: 80
      weight: 90
    - name: shop-canary
      port: 80
      weight: 10
```

```
ana@laptop:~/shop$ kubectl apply -f route.yaml
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    180 shop 1.0
     20 shop 1.1
```

**180 and 20: exactly the weights.** Traefik spreads weighted backends with a weighted round robin, not
a random draw, which is why the count came out exact. The canary served one request in ten from real
users, and anything wrong with 1.1 reached a tenth of them. A canary is only as good as what watches
it: error rates and latency for the canary's pods, compared with the stable ones, decide whether the
weight goes up or back to zero.

## A canary you can reach on purpose

Testers want to see the new version every time. A rule that matches a header comes first in the
route, and only requests that carry it skip the weights:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
spec:
  parentRefs:
  - name: public
  hostnames:
  - shop.example.test
  rules:
  - matches:
    - headers:
      - name: X-Canary
        value: "always"
    backendRefs:
    - name: shop-canary
      port: 80
  - backendRefs:
    - name: shop-stable
      port: 80
      weight: 90
    - name: shop-canary
      port: 80
      weight: 10
```

```
ana@laptop:~/shop$ kubectl apply -f route-header.yaml
httproute.gateway.networking.k8s.io/shop configured
ana@laptop:~/shop$ for i in 1 2 3; do curl -s -H "Host: shop.example.test" -H "X-Canary: always" localhost:8080/; done
shop 1.1 on shop-canary-5579dbf66c-swxxp
shop 1.1 on shop-canary-5579dbf66c-swxxp
shop 1.1 on shop-canary-5579dbf66c-swxxp
```

Every request with `X-Canary: always` reached the canary. Rules are tried in order of how specific
their matches are, so this one wins over the catch-all rule below it.

## Promoting it

When the canary has proved itself, the weights move. This patch sets the stable side to 0 and the
canary to 100:

```
ana@laptop:~/shop$ kubectl patch httproute shop --type=json -p '[{"op":"replace","path":"/spec/rules/1/backendRefs/0/weight","value":0},{"op":"replace","path":"/spec/rules/1/backendRefs/1/weight","value":100}]'
httproute.gateway.networking.k8s.io/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 1.1
```

All 200 on 1.1. What remains is housekeeping: update `shop-stable` to 1.1, move the weight back to it,
and scale the canary down, so that the next release starts from the same arrangement. Tools such as
Argo Rollouts and Flagger run these steps, and the checks between them, automatically.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Left, canary: the HTTPRoute sends weight 90 to the Service shop-stable, three pods of 1.0, and weight 10 to shop-canary, one pod of 1.1. A request with the header X-Canary always goes to the canary. Right, blue-green: one Service, shop, whose selector says colour blue, points at two pods of 1.1; two pods of 2.0 labelled green wait beside them. Changing the selector moves all traffic at once.\"><defs><marker id=\"cb-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"cb-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"cb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"cb-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">canary: shares of traffic</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTPRoute</text><rect x=\"20\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-stable</text><text x=\"90.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 × 1.0</text><rect x=\"190\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-canary</text><text x=\"260.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 × 1.1</text><path d=\"M150 76 L90 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-paper-dim)\"></path><text x=\"104\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M190 76 L260 138\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-amber)\"></path><text x=\"244\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10</text><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">X-Canary: always</text><path d=\"M370 20 L370 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blue-green: one switch</text><rect x=\"485\" y=\"34\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Service shop</text><rect x=\"395\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">blue</text><text x=\"465.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 × 1.1</text><rect x=\"560\" y=\"140\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">green</text><text x=\"630.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 × 2.0</text><path d=\"M530 76 L465 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cb-ah-phosphor)\"></path><text x=\"476\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">selector</text><text x=\"630\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ready, no traffic</text></svg>", "caption": "A canary moves a fraction of the users; blue-green moves all of them at once, and keeps the old version running to move them back."}
```
