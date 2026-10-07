#!/usr/bin/env bash
# The terminal sessions quoted in lesson 45 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster; the second scheduler, which
# is the kube-scheduler v1.37.1 binary from dl.k8s.io running on the laptop in
# the background with the administrator's kubeconfig (a real one runs in the
# cluster, as a Deployment with its own ServiceAccount); and the pauses for
# pods to be placed. Names differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block config
put shop-scheduler.yaml <<'CODE'
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: /home/ana/.kube/config
leaderElection:
  leaderElect: false
profiles:
- schedulerName: shop-scheduler
  plugins:
    score:
      disabled:
      - name: NodeResourcesBalancedAllocation
      - name: PodTopologySpread
  pluginConfig:
  - name: NodeResourcesFit
    args:
      scoringStrategy:
        type: MostAllocated
        resources:
        - name: cpu
          weight: 1
        - name: memory
          weight: 1
CODE
kube-scheduler --config shop-scheduler.yaml --secure-port=0 >scheduler.log 2>&1 & SCHED=$!
trap 'kill $SCHED 2>/dev/null' EXIT
quiet 'sleep 5'
block two
put two-ways.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread
spec:
  replicas: 4
  selector:
    matchLabels:
      app: spread
  template:
    metadata:
      labels:
        app: spread
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: packed
spec:
  replicas: 4
  selector:
    matchLabels:
      app: packed
  template:
    metadata:
      labels:
        app: packed
    spec:
      schedulerName: shop-scheduler
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 500m
CODE
run 'kubectl apply -f two-ways.yaml'
quiet 'kubectl rollout status deployment/spread --timeout=120s'
quiet 'kubectl rollout status deployment/packed --timeout=120s'
run 'kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.metadata.name'
run "kubectl get events --field-selector reason=Scheduled -o custom-columns=POD:.involvedObject.name,FROM:.reportingComponent,SOURCE:.source.component | sort | uniq | head -n 9"
block nobody
run 'kubectl run orphan --image=shop:1.0 --overrides='"'"'{"spec":{"schedulerName":"nobody"}}'"'"''
quiet 'sleep 10'
run 'kubectl get pod orphan'
run 'kubectl get events --field-selector involvedObject.name=orphan'
block extensions
run 'kubectl get apiservices | grep -v Local'
run 'kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations'
run 'kubectl get validatingadmissionpolicies'
