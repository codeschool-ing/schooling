#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, a busybox pod called `probe`,
# and the pauses that give the kubelet's probes time to fail and act. The
# shop's /break and /drain endpoints exist for this course: they make the
# health and readiness answers fail on purpose. Names, addresses and times
# differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block probes
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 2
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
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          periodSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          periodSeconds: 5
          failureThreshold: 1
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
    targetPort: http
CODE
run 'kubectl apply -f shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
run 'kubectl get pods -l app=shop -o wide'
POD=$(kubectl get pods -l app=shop -o jsonpath='{.items[0].metadata.name}')
IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}')
block readiness
run "kubectl exec probe -- wget -qO- $IP:8080/drain"
quiet 'sleep 8'
run 'kubectl get pods -l app=shop'
run 'kubectl get endpointslices -l kubernetes.io/service-name=shop -o custom-columns=ENDPOINTS:.endpoints[*].addresses[0],READY:.endpoints[*].conditions.ready'
run 'kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"'
block liveness
run "kubectl exec probe -- wget -qO- $IP:8080/break"
quiet 'sleep 25'
run 'kubectl get pods -l app=shop'
run "kubectl get events --field-selector involvedObject.name=$POD,reason=Unhealthy -o custom-columns=MESSAGE:.message | tail -n 2"
run "kubectl get events --field-selector involvedObject.name=$POD,reason=Killing -o custom-columns=MESSAGE:.message"
block startup
put slow.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: slow
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
CODE
run 'kubectl apply -f slow.yaml'
quiet 'sleep 55'
run 'kubectl get pod slow'
run 'kubectl get events --field-selector involvedObject.name=slow,reason=Killing -o custom-columns=MESSAGE:.message | head -n 2'
run 'kubectl delete pod slow --wait=false'
put slow-fixed.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: slow-fixed
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: STARTUP_DELAY
      value: "30"
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 12
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
CODE
run 'kubectl apply -f slow-fixed.yaml'
quiet 'sleep 50'
run 'kubectl get pod slow-fixed'
