#!/usr/bin/env bash
# The terminal sessions quoted in lesson 32 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster; the pauses that let the
# kubelet and the node controller act; and the "failed" node, which is the
# shop-worker2 container stopped with `docker stop`, which is what a machine
# that loses power looks like to the rest of the cluster. Names and times
# differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block conditions
run 'kubectl describe node shop-worker | grep -A 7 "^Conditions"'
block ephemeral
put scribbler.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: scribbler
spec:
  restartPolicy: Never
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "dd if=/dev/zero of=/tmp/fill bs=1M count=80; sleep 3600"]
    resources:
      limits:
        ephemeral-storage: 50Mi
CODE
run 'kubectl apply -f scribbler.yaml'
quiet 'sleep 30'
run 'kubectl get pod scribbler'
run 'kubectl get pod scribbler -o jsonpath="{.status.reason}: {.status.message}"; echo'
block drain
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 4
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
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: shop
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: shop
CODE
run 'kubectl apply -f shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pdb shop'
run 'kubectl get pods -l app=shop -o wide'
run 'kubectl drain shop-worker --ignore-daemonsets --delete-emptydir-data --timeout=60s'
run 'kubectl get pods -l app=shop -o wide'
run 'kubectl get node shop-worker'
run 'kubectl uncordon shop-worker'
block node-lost
put shop-fast.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 4
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      tolerations:
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      containers:
      - name: shop
        image: shop:1.0
CODE
quiet 'kubectl delete pdb shop'
run 'kubectl apply -f shop-fast.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -l app=shop -o wide'
run 'docker stop shop-worker2'
quiet 'sleep 50'
run 'kubectl get node shop-worker2'
run 'kubectl get node shop-worker2 -o jsonpath="{.spec.taints[*].key}"; echo'
quiet 'sleep 45'
run 'kubectl get pods -l app=shop -o wide'
