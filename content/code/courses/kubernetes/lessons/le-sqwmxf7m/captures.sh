#!/usr/bin/env bash
# The terminal sessions quoted in lesson 40 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and the pauses that let each
# broken pod reach the state the lesson reads. The lab's nodes cannot reach
# any registry (see lab.sh), so the image that does not exist fails the way
# an unreachable registry fails; the lesson says so. Names, ages and times
# differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block five
put broken.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: typo
spec:
  containers:
  - name: shop
    image: shop:1.O
---
apiVersion: v1
kind: Pod
metadata:
  name: crashing
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: CRASH
      value: "yes"
---
apiVersion: v1
kind: Pod
metadata:
  name: greedy
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: "64"
---
apiVersion: v1
kind: Pod
metadata:
  name: unconfigured
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: GREETING
      valueFrom:
        configMapKeyRef:
          name: shop-settings
          key: greeting
---
apiVersion: v1
kind: Pod
metadata:
  name: never-ready
spec:
  containers:
  - name: shop
    image: shop:1.0
    readinessProbe:
      httpGet:
        path: /ready
        port: 9090
      periodSeconds: 3
CODE
run 'kubectl apply -f broken.yaml'
quiet 'sleep 60'
run 'kubectl get pods'
block typo
run "kubectl describe pod typo | sed -n '/^Events/,\$p'"
block crashing
run 'kubectl logs crashing'
run 'kubectl get pod crashing -o jsonpath="{.status.containerStatuses[0].lastState.terminated.exitCode} {.status.containerStatuses[0].restartCount}"; echo'
block greedy
run 'kubectl get events --field-selector involvedObject.name=greedy -o custom-columns=REASON:.reason,MESSAGE:.message'
block unconfigured
run 'kubectl get pod unconfigured -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo'
run 'kubectl create configmap shop-settings --from-literal=greeting=hello'
quiet 'sleep 15'
run 'kubectl get pod unconfigured'
block never-ready
run 'kubectl get events --field-selector involvedObject.name=never-ready -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message'
run "kubectl describe pod never-ready | grep -E '^ +Ready|Readiness'"
block order
run 'kubectl get events --sort-by=.metadata.creationTimestamp -o custom-columns=OBJECT:.involvedObject.name,REASON:.reason | tail -n 12'
