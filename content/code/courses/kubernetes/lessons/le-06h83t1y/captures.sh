#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and reading the nodes' routes
# and interfaces with `docker exec`, because a kind node is a container. Pod
# addresses, interface names and node addresses differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block pod-cidrs
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address,POD-CIDR:.spec.podCIDR'
put pods.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: left
spec:
  nodeName: shop-worker
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: right
spec:
  nodeName: shop-worker2
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
CODE
run 'kubectl apply -f pods.yaml'
quiet 'kubectl wait --for=condition=Ready pod/left pod/right --timeout=60s'
run 'kubectl get pods -o wide'
block inside
run 'kubectl exec left -- ip -4 addr show eth0'
run 'kubectl exec left -- ip route'
RIGHT=$(kubectl get pod right -o jsonpath='{.status.podIP}')
run "kubectl exec left -- ping -c 3 $RIGHT"
run "kubectl exec left -- traceroute -n -m 4 $RIGHT"
block node-routes
run 'docker exec shop-worker ip route'
LEFT=$(kubectl get pod left -o jsonpath='{.status.podIP}')
run "docker exec shop-worker ip route get $LEFT"
run 'docker exec shop-worker cat /etc/cni/net.d/10-kindnet.conflist'
