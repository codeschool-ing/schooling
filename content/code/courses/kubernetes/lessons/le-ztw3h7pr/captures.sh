#!/usr/bin/env bash
# The terminal sessions quoted in lesson 31 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the zone labels on the two
# workers (kind nodes have no zones; a cloud's nodes carry these labels from
# the start), and the pauses that let the scheduler act. Names differ on every
# run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl label node shop-worker topology.kubernetes.io/zone=sa-east-1a'
quiet 'kubectl label node shop-worker2 topology.kubernetes.io/zone=sa-east-1b'

block zones
run 'kubectl get nodes -L topology.kubernetes.io/zone'
block spread
put spread.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 6
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: shop
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f spread.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.spec.nodeName'
run 'kubectl scale deployment shop --replicas=7'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -l app=shop -o custom-columns=NODE:.spec.nodeName --no-headers | sort | uniq -c'
quiet 'kubectl delete deployment shop'
block priority
put priorities.yaml <<'CODE'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: checkout
value: 100000
description: "The path that takes customers' money."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch
value: 1000
description: "Reports and other work that can wait."
CODE
run 'kubectl apply -f priorities.yaml'
run 'kubectl get priorityclasses'
put batch.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch
spec:
  replicas: 4
  selector:
    matchLabels:
      app: batch
  template:
    metadata:
      labels:
        app: batch
    spec:
      priorityClassName: batch
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
CODE
run 'kubectl apply -f batch.yaml'
quiet 'kubectl rollout status deployment/batch --timeout=120s'
run 'kubectl get pods -l app=batch -o wide'
put checkout.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      priorityClassName: checkout
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
CODE
run 'kubectl apply -f checkout.yaml'
quiet 'sleep 20'
run 'kubectl get pods -l "app in (batch,checkout)" -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,STATUS:.status.phase,NODE:.spec.nodeName'
run 'kubectl get events --field-selector reason=Preempted -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message'
