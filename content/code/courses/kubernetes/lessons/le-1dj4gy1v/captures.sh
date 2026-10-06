#!/usr/bin/env bash
# The terminal sessions quoted in lesson 33 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, and metrics-server (lab.sh metrics), which the autoscaler
#     reads.
#   - a busybox pod called `load` that sends the shop work in a loop, started
#     and stopped in the background between listings, and the pauses while
#     the autoscaler reacts. Every utilisation figure is a measurement of this
#     laptop at that moment and differs on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
lab metrics >/dev/null 2>&1
quiet 'kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s'
quiet 'kubectl run load --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block deploy
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
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
            cpu: 200m
            memory: 32Mi
          limits:
            memory: 64Mi
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
block hpa
put hpa.yaml <<'CODE'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shop
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  minReplicas: 1
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
CODE
run 'kubectl apply -f hpa.yaml'
quiet 'kubectl wait pod/load --for=condition=Ready --timeout=60s'
quiet 'sleep 60'
run 'kubectl get hpa shop'
block load
# Four loops at once, each asking for 300 ms of work at a time.
kubectl exec load -- sh -c 'for n in 1 2 3 4; do (end=$(($(date +%s)+150)); while [ $(date +%s) -lt $end ]; do wget -qO- "shop/work?ms=300" >/dev/null; done) & done; wait' >/dev/null 2>&1 & LOAD=$!
quiet 'sleep 45'
run 'kubectl get hpa shop'
quiet 'sleep 60'
run 'kubectl get hpa shop'
run 'kubectl get pods -l app=shop'
run "kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler -o custom-columns=REASON:.reason,MESSAGE:.message"
wait "$LOAD" 2>/dev/null
block calm
quiet 'sleep 90'
run 'kubectl get hpa shop'
run "kubectl describe hpa shop | sed -n '/^Conditions/,/^Events/p'"
