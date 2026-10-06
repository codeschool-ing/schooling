#!/usr/bin/env bash
# The terminal sessions quoted in lesson 35 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, and a busybox pod called `probe` inside it.
#   - during the counted requests, the change of version is made from a second
#     terminal, three seconds into the loop; the lesson shows that command on
#     its own line, as it was typed there.
#   - the pauses that let a rollout finish or get stuck.
# The counts come from real requests and differ on every run; so do names.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block deploy
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
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
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 2
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
quiet 'kubectl wait pod/probe --for=condition=Ready --timeout=60s'
run 'kubectl get rs -l app=shop'
block update
COUNT='kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- -T 2 shop || echo FAILED; sleep 0.1; done" | cut -d" " -f1,2 | sort | uniq -c'
counted() { # COMMAND: run it from a "second terminal" three seconds into the count
  (sleep 3; eval "$1" >/tmp/update.out 2>&1) & BG=$!
  run "$COUNT"
  wait "$BG"
  prompt "$1"
  cat /tmp/update.out
  quiet 'kubectl rollout status deployment/shop --timeout=120s'
}
counted 'kubectl set image deployment/shop shop=shop:1.1'
run 'kubectl get rs -l app=shop'
block graceful
put graceful.yaml <<'CODE'
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: shop
        lifecycle:
          preStop:
            sleep:
              seconds: 10
CODE
run 'kubectl patch deployment shop --patch-file graceful.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=180s'
counted 'kubectl set image deployment/shop shop=shop:2.0'
block bad
run 'kubectl set env deployment/shop CRASH=1'
quiet 'sleep 40'
run 'kubectl rollout status deployment/shop --timeout=10s'
run 'kubectl get pods -l app=shop'
run "$COUNT"
block undo
run 'kubectl rollout history deployment/shop'
run 'kubectl rollout history deployment/shop --revision=4 | grep -E "Image|CRASH"'
run 'kubectl rollout undo deployment/shop'
quiet 'kubectl rollout status deployment/shop --timeout=180s'
run 'kubectl get pods -l app=shop'
run 'kubectl rollout history deployment/shop'
