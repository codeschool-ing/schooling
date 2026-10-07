#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses that let the
# ReplicaSet try, and fail, to make pods. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block namespace
run 'kubectl create namespace team-a'
put quota.yaml <<'CODE'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a
  namespace: team-a
spec:
  hard:
    pods: "4"
    requests.cpu: "1"
    requests.memory: 512Mi
    limits.memory: 1Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 64Mi
    default:
      memory: 128Mi
    max:
      memory: 256Mi
CODE
run 'kubectl apply -f quota.yaml'
run 'kubectl describe resourcequota team-a -n team-a'
block defaults
run 'kubectl create deployment shop --image=shop:1.0 --replicas=2 -n team-a'
quiet 'kubectl -n team-a rollout status deployment/shop --timeout=120s'
run 'kubectl get pod -n team-a -l app=shop -o jsonpath="{.items[0].spec.containers[0].resources}"; echo'
block exceed
run 'kubectl scale deployment shop --replicas=6 -n team-a'
quiet 'sleep 8'
run 'kubectl get deployment shop -n team-a'
run 'kubectl get events -n team-a --field-selector reason=FailedCreate -o custom-columns=MESSAGE:.message | tail -n 1'
run 'kubectl describe resourcequota team-a -n team-a | tail -n 5'
block too-big
put greedy.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: greedy
  namespace: team-a
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      limits:
        memory: 512Mi
CODE
run 'kubectl apply -f greedy.yaml'
block other-namespace
run 'kubectl create deployment shop --image=shop:1.0 --replicas=6'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get deployments --all-namespaces -l app=shop'
