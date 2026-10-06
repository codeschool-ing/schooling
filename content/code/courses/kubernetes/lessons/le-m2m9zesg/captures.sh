#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, a busybox pod called `probe`
# that sends the shop requests from inside the cluster, looking up each pod's
# address for it, and the pauses that let a pod be scheduled or killed before
# the next listing. The loop counts
# depend on the laptop's CPU and on what else it was doing, and differ on
# every run; so do names and ages.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'

block allocatable
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory'
block requests
put big.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: big
spec:
  replicas: 5
  selector:
    matchLabels:
      app: big
  template:
    metadata:
      labels:
        app: big
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1500m"
            memory: 64Mi
CODE
run 'kubectl apply -f big.yaml'
quiet 'sleep 10'
run 'kubectl get pods -l app=big -o wide'
run 'kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1'
run 'kubectl describe node shop-worker | grep -A 8 "Allocated resources"'
quiet 'kubectl delete -f big.yaml'
block cpu-limit
put cpu.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: capped
  labels:
    app: capped
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: free
  labels:
    app: free
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
CODE
run 'kubectl apply -f cpu.yaml'
quiet 'kubectl wait --for=condition=Ready pod/capped pod/free --timeout=60s'
CAPPED=$(kubectl get pod capped -o jsonpath='{.status.podIP}')
FREE=$(kubectl get pod free -o jsonpath='{.status.podIP}')
run "kubectl exec probe -- wget -qO- '$FREE:8080/work?ms=1000'"
run "kubectl exec probe -- wget -qO- '$CAPPED:8080/work?ms=1000'"
block memory-limit
put hungry.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: hungry
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        memory: 64Mi
      limits:
        memory: 64Mi
CODE
run 'kubectl apply -f hungry.yaml'
quiet 'kubectl wait --for=condition=Ready pod/hungry --timeout=60s'
HUNGRY=$(kubectl get pod hungry -o jsonpath='{.status.podIP}')
run "kubectl exec probe -- wget -qO- '$HUNGRY:8080/eat?mb=30'"
run "kubectl exec probe -- wget -qO- -T 5 '$HUNGRY:8080/eat?mb=60'"
quiet 'sleep 5'
run 'kubectl get pod hungry'
run 'kubectl get pod hungry -o jsonpath="{.status.containerStatuses[0].lastState.terminated}"; echo'
block qos
run 'kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass'
