#!/usr/bin/env bash
# The terminal sessions quoted in lesson 30 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster and the pauses that let the
# scheduler and the taint manager act. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block control-plane
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key'
block taint
run 'kubectl taint node shop-worker2 dedicated=reports:NoSchedule'
run 'kubectl create deployment shop --image=shop:1.0 --replicas=4'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get pods -l app=shop -o wide'
block tolerate
put reports.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reports
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reports
  template:
    metadata:
      labels:
        app: reports
    spec:
      tolerations:
      - key: dedicated
        operator: Equal
        value: reports
        effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: shop-worker2
      containers:
      - name: shop
        image: shop:1.0
CODE
run 'kubectl apply -f reports.yaml'
quiet 'kubectl rollout status deployment/reports --timeout=120s'
run 'kubectl get pods -l app=reports -o wide'
block noexecute
run 'kubectl get pods -o wide --field-selector spec.nodeName=shop-worker'
run 'kubectl taint node shop-worker maintenance=now:NoExecute'
quiet 'sleep 10'
run 'kubectl get pods -o wide -l app=shop'
run 'kubectl get events --field-selector reason=TaintManagerEviction -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message | head -n 3'
block untaint
run 'kubectl taint node shop-worker maintenance=now:NoExecute-'
run 'kubectl taint node shop-worker2 dedicated=reports:NoSchedule-'
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key'
block default-tolerations
run 'kubectl get pod -l app=shop -o jsonpath="{.items[0].spec.tolerations}"; echo'
