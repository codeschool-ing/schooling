#!/usr/bin/env bash
# The terminal sessions quoted in lesson 41 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the shop Deployment, and the
# pauses for it to start and be called. No monitoring system is installed:
# the lesson reads what the cluster's own components expose, which is what
# such a system collects. Values differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl create deployment shop --image=shop:1.0 --replicas=2'
quiet 'kubectl expose deployment shop --port 80 --target-port 8080'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sh -c "for i in \$(seq 20); do wget -qO- shop >/dev/null; done; sleep 3600"'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
quiet 'sleep 20'

block apiserver
run 'kubectl get --raw /metrics | grep -c "^# HELP"'
run 'kubectl get --raw /metrics | grep "^apiserver_request_total{" | grep "resource=\"pods\"" | head -n 4'
block kubelet
run 'kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/resource | grep "^container_memory_working_set_bytes" | grep shop | head -n 2'
run 'kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/cadvisor | grep -c "^container_"'
block logs
POD=$(kubectl get pods -l app=shop -o jsonpath='{.items[0].metadata.name}')
NODE=$(kubectl get pod "$POD" -o jsonpath='{.spec.nodeName}')
run "docker exec $NODE ls /var/log/pods | grep shop"
run "docker exec $NODE sh -c 'tail -n 2 /var/log/pods/default_${POD}_*/shop/0.log'"
run "kubectl logs $POD --tail=2"
block app
run 'kubectl exec probe -- wget -qO- shop/metrics'
