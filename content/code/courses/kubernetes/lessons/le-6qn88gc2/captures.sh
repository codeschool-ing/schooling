#!/usr/bin/env bash
# The terminal sessions quoted in lesson 48 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: two clusters, `shop` and `eu`, made one
# after the other by lab.sh with the same configuration; kind adds each to the
# same kubeconfig as a context of its own. Names, addresses and ages differ on
# every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
lab down >/dev/null 2>&1
fresh
lab up /var/tmp/lab-cluster.yaml eu >/dev/null 2>&1 || { echo "##### the second cluster did not come up" >&2; exit 1; }

block contexts
run 'kubectl config get-contexts'
run 'kubectl config current-context'
run 'kubectl --context kind-shop get nodes'
run 'kubectl --context kind-eu get nodes'
block kubeconfig
run "kubectl config view -o jsonpath='{range .clusters[*]}{.name}{\"  \"}{.cluster.server}{\"\\n\"}{end}'"
block both
run 'for c in kind-shop kind-eu; do kubectl --context $c create deployment shop --image=shop:1.0 --replicas=2; done'
quiet 'kubectl --context kind-shop rollout status deployment/shop --timeout=120s'
quiet 'kubectl --context kind-eu rollout status deployment/shop --timeout=120s'
run 'for c in kind-shop kind-eu; do echo "== $c"; kubectl --context $c get pods -l app=shop -o wide | cut -c1-90; done'
block switch
run 'kubectl config use-context kind-shop'
run 'kubectl delete deployment shop'
run 'for c in kind-shop kind-eu; do echo "$c: $(kubectl --context $c get deployments --no-headers 2>/dev/null | wc -l) deployment(s)"; done'
block isolated
run 'kubectl --context kind-shop get namespaces --no-headers | wc -l'
run 'kubectl --context kind-shop get nodes -o name; kubectl --context kind-eu get nodes -o name'
