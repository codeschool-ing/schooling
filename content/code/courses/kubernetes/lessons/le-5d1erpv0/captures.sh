#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, and metrics-server installed from its own manifests with
#     the image lab.sh built from its source (lab.sh metrics).
#   - a busybox pod called `probe` that sends the shop work from inside the
#     cluster, in the background, for the measurement under load.
# Every number from `kubectl top` is a measurement of this laptop at that
# moment and differs on every run; so do names.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
lab metrics >/dev/null 2>&1
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block csr
run 'kubectl get csr -o custom-columns=NAME:.metadata.name,SIGNER:.spec.signerName,REQUESTOR:.spec.username,CONDITION:.status.conditions[0].type'
quiet 'kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s'
block apiservice
run 'kubectl get apiservice v1beta1.metrics.k8s.io'
run 'kubectl -n kube-system get deployment metrics-server -o jsonpath="{.spec.template.spec.containers[0].args}"; echo'
block top-nodes
put shop.yaml <<'CODE'
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
        resources:
          requests:
            cpu: 500m
            memory: 256Mi
          limits:
            memory: 256Mi
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
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
quiet 'sleep 75'
run 'kubectl top nodes'
run 'kubectl top pods -l app=shop'
block waste
run 'kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,CPU-REQUEST:.spec.containers[0].resources.requests.cpu,MEMORY-REQUEST:.spec.containers[0].resources.requests.memory'
run 'kubectl describe node shop-worker | grep -A 6 "Allocated resources"'
block load
kubectl exec probe -- sh -c 'end=$(($(date +%s)+90)); while [ $(date +%s) -lt $end ]; do wget -qO- "shop/work?ms=200" >/dev/null; done' >/dev/null 2>&1 & LOAD=$!
quiet 'sleep 75'
run 'kubectl top pods -l app=shop'
run 'kubectl top pods -l app=shop --containers --sort-by=cpu | head -n 2'
wait "$LOAD" 2>/dev/null
block raw
run 'kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes/shop-worker | head -c 300; echo'
