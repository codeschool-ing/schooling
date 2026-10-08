#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the two clusters (`fresh` makes "shop";
# kind makes "study" quietly beside it) and the pauses for rollouts. The
# port in the server address, the names of pods and the ages differ on every
# run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kind create cluster --name study --config /var/tmp/lab-cluster.yaml --image kindest/node:v1.37.0 -q'
quiet 'kubectl config use-context kind-shop'

block kubeconfig
run 'kubectl config get-contexts'
run 'kubectl config view --minify'
block switch
run 'kubectl config use-context kind-study'
run 'kubectl get nodes'
run 'kubectl config use-context kind-shop'
run 'kubectl --context kind-study get nodes -o name'
block namespaces
run 'kubectl create namespace dev'
run 'kubectl config set-context --current --namespace=dev'
run 'kubectl get pods'
run 'kubectl get pods -n kube-system -l component=etcd'
run 'kubectl get pods --all-namespaces --no-headers | wc -l'
quiet 'kubectl config set-context --current --namespace=default'
block generate
run 'kubectl create deployment web --image=shop:1.0 --replicas=2 --dry-run=client -o yaml > deployment.yaml'
run 'cat deployment.yaml'
block apply
run 'kubectl apply -f deployment.yaml'
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl apply -f deployment.yaml'
run 'sed -i "s/replicas: 2/replicas: 3/" deployment.yaml'
run 'kubectl diff -f deployment.yaml'
run 'kubectl apply -f deployment.yaml'
block drift
quiet 'kubectl rollout status deployment/web --timeout=120s'
run 'kubectl scale deployment web --replicas=5'
run 'kubectl diff -f deployment.yaml'
run 'kubectl apply -f deployment.yaml'
quiet 'sleep 3'
run 'kubectl get deployment web'
block delete
run 'kubectl delete -f deployment.yaml'
quiet 'kind delete cluster --name study'
