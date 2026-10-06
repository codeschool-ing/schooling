#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, from lab/cluster-ports.yaml, so the laptop's 8080 reaches
#     the controller's NodePort.
#   - the controller itself: Traefik v3.6 from lab/traefik.yaml, and the
#     Gateway API's standard CRDs at v1.4.0, the version that Traefik release
#     is built against (lab.sh copies them from the project's Go module).
#     Installing a controller is a chart or a manifest from its vendor; the
#     lesson shows what is installed, not the install.
#   - two small Deployments to route to: the shop, and `admin`, which is the
#     shop image again with a different greeting.
# The hostnames are under example.test, a name reserved for testing, and curl
# is told which one it is asking with --resolve or a Host header.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh "$COURSE/lab/cluster-ports.yaml"
lab load traefik:v3.6 >/dev/null 2>&1
quiet 'kubectl apply -f /opt/k8s/manifests/gateway-api-v1.4.0/'
quiet 'kubectl apply -f "$COURSE/lab/traefik.yaml"'
quiet 'kubectl -n traefik rollout status deployment/traefik --timeout=120s'
cat >/tmp/apps.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 2
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Service
metadata: {name: shop}
spec: {selector: {app: shop}, ports: [{port: 80, targetPort: 8080}]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: admin}
spec:
  replicas: 1
  selector: {matchLabels: {app: admin}}
  template:
    metadata: {labels: {app: admin}}
    spec: {containers: [{name: admin, image: "shop:1.0", env: [{name: GREETING, value: "admin"}]}]}
---
apiVersion: v1
kind: Service
metadata: {name: admin}
spec: {selector: {app: admin}, ports: [{port: 80, targetPort: 8080}]}
CODE
quiet 'kubectl apply -f /tmp/apps.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl rollout status deployment/admin --timeout=120s'

block controller
run 'kubectl get pods -n traefik'
run 'kubectl get ingressclass'
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8080'
block ingress
put ingress.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
spec:
  ingressClassName: traefik
  rules:
  - host: shop.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 80
CODE
run 'kubectl apply -f ingress.yaml'
quiet 'sleep 3'
run 'kubectl get ingress shop'
run 'curl -s -H "Host: shop.example.test" localhost:8080/'
run 'curl -s -H "Host: shop.example.test" localhost:8080/admin'
run 'curl -s -o /dev/null -w "%{http_code}\n" -H "Host: other.example.test" localhost:8080/'
block no-class
put stray.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: stray
spec:
  ingressClassName: nginx
  rules:
  - host: stray.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
CODE
run 'kubectl apply -f stray.yaml'
quiet 'sleep 3'
run 'kubectl get ingress'
run 'curl -s -o /dev/null -w "%{http_code}\n" -H "Host: stray.example.test" localhost:8080/'
quiet 'kubectl delete -f stray.yaml'
quiet 'kubectl delete -f ingress.yaml'
block gateway
put gateway.yaml <<'CODE'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public
spec:
  gatewayClassName: traefik
  listeners:
  - name: web
    protocol: HTTP
    port: 8000
    allowedRoutes:
      namespaces:
        from: Same
CODE
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
  - matches:
    - path:
        type: PathPrefix
        value: /admin
      headers:
      - name: X-Staff
        value: "yes"
    backendRefs:
    - name: admin
      port: 80
  - backendRefs:
    - name: shop
      port: 80
CODE
run 'kubectl apply -f gateway.yaml -f route.yaml'
quiet 'sleep 5'
run 'kubectl get gatewayclass,gateway'
run 'kubectl get httproute shop -o jsonpath="{.status.parents[0].conditions[*].type}"; echo'
run 'curl -s -H "Host: shop.example.test" localhost:8080/admin'
run 'curl -s -H "Host: shop.example.test" -H "X-Staff: yes" localhost:8080/admin'
run 'kubectl api-resources --api-group=gateway.networking.k8s.io'
