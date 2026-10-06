#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster (`fresh`, which is lab.sh up:
# one control-plane node and two workers), and waiting for the rollout to
# finish before the pods are listed. The tail of every pod's name, its address
# and the ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block nodes
run 'kubectl get nodes'
block resources
run 'kubectl api-resources --no-headers | wc -l'
run 'kubectl api-resources | head -n 12'
block create
run 'kubectl create deployment web --image=shop:1.0 --replicas=3'
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl get deployments,replicasets,pods'
block wanted
run 'kubectl get deployment web -o custom-columns=NAME:.metadata.name,WANTED:.spec.replicas,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image'
block one-pod
run 'POD=$(kubectl get pods -l app=web -o name | head -n 1); echo $POD'
run 'kubectl get $POD -o yaml | head -n 24'
run 'kubectl get $POD -o custom-columns=PHASE:.status.phase,IP:.status.podIP,NODE:.spec.nodeName'
block labels
run 'kubectl get pods --show-labels'
run 'kubectl get pods -l app=web -o wide'
block namespaces
run 'kubectl get namespaces'
run 'kubectl get pods -n kube-system'
block explain
run 'kubectl explain deployment.spec.replicas'
