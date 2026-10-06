#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses that let a
# controller act before the next listing. Pod names, hashes and ages differ on
# every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block deploy
put web.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f web.yaml'
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl get replicasets'
run 'kubectl get replicaset -l app=web -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,SELECTOR:.spec.selector.matchLabels'
block delete-one
run 'kubectl get pods'
run 'kubectl delete pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2)'
run 'kubectl get pods'
block relabel
run 'kubectl label pod $(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2) app=debug --overwrite'
quiet 'sleep 3'
run 'kubectl get pods -L app'
run 'kubectl get replicaset -l app=web'
block scale
run 'kubectl scale deployment web --replicas=5'
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl get deployment web'
run 'kubectl scale deployment web --replicas=2'
quiet 'sleep 5'
run 'kubectl get pods -l app=web'
block template
run 'kubectl set image deployment/web shop=shop:1.1'
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl get replicasets -l app=web'
run 'kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image'
block rs-alone
run 'kubectl delete replicaset -l app=web --cascade=foreground'
quiet 'sleep 5'
run 'kubectl get replicasets -l app=web'
