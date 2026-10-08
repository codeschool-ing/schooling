#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, made from lesson 8's ports.yaml
# so that the laptop's port 8080 reaches the NodePort; and the port-forward,
# which is started in the background and stopped by its pid. The tail of each
# pod's name, which the shop prints as its hostname, differs on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
shown "$COURSE/lessons/le-nf7qt63y/the-manifest.md" ports.yaml >/tmp/ports.yaml || exit 1
fresh /tmp/ports.yaml

block manifest
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  labels:
    app: shop
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
        - containerPort: 8080
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
CODE
run 'kubectl apply -f shop.yaml'
run 'kubectl rollout status deployment/shop'
run 'kubectl get pods -o wide'
run 'kubectl get service shop'
block forward
kubectl port-forward service/shop 8081:80 >/tmp/pf.log 2>&1 </dev/null & PF=$!
quiet 'sleep 2'
prompt 'kubectl port-forward service/shop 8081:80 &'
cat /tmp/pf.log
run 'curl -s localhost:8081'
run 'curl -s localhost:8081/healthz'
kill "$PF"; wait "$PF" 2>/dev/null
block nodeport
put shop-nodeport.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
CODE
run 'kubectl apply -f shop-nodeport.yaml'
run 'kubectl get service shop-public'
quiet 'sleep 2'
run 'for i in 1 2 3 4 5 6; do curl -s localhost:8080; done'
block logs
run 'kubectl logs deployment/shop --all-pods --prefix | grep GET'
