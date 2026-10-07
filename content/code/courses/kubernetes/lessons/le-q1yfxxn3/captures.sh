#!/usr/bin/env bash
# The terminal sessions quoted in lesson 36 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster (lab/cluster-ports.yaml), Traefik v3.6 with the Gateway API
#     CRDs v1.4.0 (lab/traefik.yaml, as lesson 16 installed them), and the
#     GatewayClass and Gateway of lesson 16, applied again.
#   - the pauses that let Traefik read a changed route.
# The counts come from real requests and differ on every run; so do names.
# The hostname is under example.test, a name reserved for testing.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh "$COURSE/lab/cluster-ports.yaml"
lab load traefik:v3.6 >/dev/null 2>&1
quiet 'kubectl apply -f /opt/k8s/manifests/gateway-api-v1.4.0/'
quiet 'kubectl apply -f "$COURSE/lab/traefik.yaml"'
quiet 'kubectl -n traefik rollout status deployment/traefik --timeout=120s'
cat >/tmp/gateway.yaml <<'CODE'
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
CODE
quiet 'kubectl apply -f /tmp/gateway.yaml'

block versions
put versions.yaml <<'CODE'
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
CODE
run 'kubectl apply -f versions.yaml'
quiet 'kubectl rollout status deployment/shop-stable --timeout=120s'
quiet 'kubectl rollout status deployment/shop-canary --timeout=120s'
run 'kubectl get pods -l app=shop -L track'
COUNT='for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c'
block weights
put route.yaml <<'CODE'
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
CODE
run 'kubectl apply -f route.yaml'
quiet 'sleep 5'
run "$COUNT"
block header
put route-header.yaml <<'CODE'
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
CODE
run 'kubectl apply -f route-header.yaml'
quiet 'sleep 5'
run 'for i in 1 2 3; do curl -s -H "Host: shop.example.test" -H "X-Canary: always" localhost:8080/; done'
block promote
run "kubectl patch httproute shop --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/rules/1/backendRefs/0/weight\",\"value\":0},{\"op\":\"replace\",\"path\":\"/spec/rules/1/backendRefs/1/weight\",\"value\":100}]'"
quiet 'sleep 5'
run "$COUNT"
block blue-green
quiet 'kubectl delete -f versions.yaml -f route-header.yaml'
put blue-green.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-blue
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: blue
  template:
    metadata:
      labels:
        app: shop
        colour: blue
    spec:
      containers:
      - name: shop
        image: shop:1.1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-green
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: green
  template:
    metadata:
      labels:
        app: shop
        colour: green
    spec:
      containers:
      - name: shop
        image: shop:2.0
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
    colour: blue
  ports:
  - port: 80
    targetPort: 8080
CODE
cat >/tmp/plain-route.yaml <<'CODE'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: shop}
spec:
  parentRefs: [{name: public}]
  hostnames: [shop.example.test]
  rules: [{backendRefs: [{name: shop, port: 80}]}]
CODE
quiet 'kubectl apply -f /tmp/plain-route.yaml'
run 'kubectl apply -f blue-green.yaml'
quiet 'kubectl rollout status deployment/shop-blue --timeout=120s'
quiet 'kubectl rollout status deployment/shop-green --timeout=120s'
quiet 'sleep 5'
run 'curl -s -H "Host: shop.example.test" localhost:8080/'
run "kubectl patch service shop -p '{\"spec\":{\"selector\":{\"app\":\"shop\",\"colour\":\"green\"}}}'"
quiet 'sleep 3'
run "$COUNT"
run "kubectl patch service shop -p '{\"spec\":{\"selector\":{\"app\":\"shop\",\"colour\":\"blue\"}}}'"
quiet 'sleep 3'
run "$COUNT"
