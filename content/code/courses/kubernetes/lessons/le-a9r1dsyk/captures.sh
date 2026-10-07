#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, the pauses that let the pod
# start, and stopping one container from the node's runtime (crictl, through
# `docker exec`), which stands in for a process that dies on its own. Names,
# addresses and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block pod
put pod.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
spec:
  initContainers:
  - name: greet
    image: busybox:1.37
    command: ["sh", "-c", "echo 'hello from the init container' > /work/greeting"]
    volumeMounts:
    - name: work
      mountPath: /work
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: CONFIG_FILE
      value: /work/greeting
    volumeMounts:
    - name: work
      mountPath: /work
  - name: sidecar
    image: busybox:1.37
    command: ["sh", "-c", "while true; do wget -qO- localhost:8080; sleep 5; done"]
  volumes:
  - name: work
    emptyDir: {}
CODE
run 'kubectl apply -f pod.yaml'
quiet 'kubectl wait --for=condition=Ready pod/web --timeout=120s'
run 'kubectl get pod web -o wide'
run 'kubectl get pod web -o custom-columns=INIT:.status.initContainerStatuses[0].state.terminated.reason,IP:.status.podIP'
block shared
quiet 'sleep 6'
run 'kubectl logs web -c sidecar'
run 'kubectl exec web -c sidecar -- wget -qO- localhost:8080/config'
run 'kubectl exec web -c sidecar -- hostname'
block restart
NODE=$(kubectl get pod web -o jsonpath='{.spec.nodeName}')
run "docker exec $NODE crictl stop \$(docker exec $NODE crictl ps --name sidecar -q)"
quiet 'sleep 8'
run 'kubectl get pod web'
run 'kubectl get pod web -o custom-columns=CONTAINER:.status.containerStatuses[*].name,RESTARTS:.status.containerStatuses[*].restartCount'
block by-hand
run 'kubectl delete pod web'
run 'kubectl get pods'
