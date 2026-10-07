#!/usr/bin/env bash
# The terminal sessions quoted in lesson 29 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses that let the
# scheduler act. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block labels
run 'kubectl label node shop-worker2 disk=ssd'
run 'kubectl get nodes -L disk'
block nodeselector
put on-ssd.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search
spec:
  replicas: 3
  selector:
    matchLabels:
      app: search
  template:
    metadata:
      labels:
        app: search
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f on-ssd.yaml'
quiet 'kubectl rollout status deployment/search --timeout=120s'
run 'kubectl get pods -l app=search -o wide'
block impossible
run 'kubectl patch deployment search -p '"'"'{"spec":{"template":{"spec":{"nodeSelector":{"disk":"nvme"}}}}}'"'"''
quiet 'sleep 8'
run 'kubectl get pods -l app=search'
run 'kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1'
quiet 'kubectl delete deployment search'
block preferred
put prefer-ssd.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
spec:
  replicas: 4
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: disk
                operator: In
                values: ["nvme", "ssd"]
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f prefer-ssd.yaml'
quiet 'kubectl rollout status deployment/cache --timeout=120s'
run 'kubectl get pods -l app=cache -o wide'
quiet 'kubectl delete deployment cache'
block anti
put spread-out.yaml <<'CODE'
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
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f spread-out.yaml'
quiet 'sleep 10'
run 'kubectl get pods -l app=shop -o wide'
run 'kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1'
block together
put next-to-shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidekick
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sidekick
  template:
    metadata:
      labels:
        app: sidekick
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: box
        image: busybox:1.37
        command: ["sleep", "3600"]
CODE
run 'kubectl apply -f next-to-shop.yaml'
quiet 'kubectl rollout status deployment/sidekick --timeout=120s'
run 'kubectl get pods -l "app in (shop,sidekick)" -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName'
