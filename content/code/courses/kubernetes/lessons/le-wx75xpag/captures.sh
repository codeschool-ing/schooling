#!/usr/bin/env bash
# The terminal sessions quoted in lesson 39 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster; a git repository on the
# laptop holding the shop's manifests, made before the lesson starts; and
# the pauses that let pods start. Neither Argo CD nor Flux is installed: the
# lesson does by hand, with git and kubectl, the loop those tools automate,
# and says so. Commit ids, names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
rm -rf /home/ana/shop/platform
mkdir -p /home/ana/shop/platform/shop
cat >/home/ana/shop/platform/shop/deployment.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
CODE
cat >/home/ana/shop/platform/shop/kustomization.yaml <<'CODE'
resources:
- deployment.yaml
CODE
(cd /home/ana/shop/platform && git init -q -b main && git config user.name Ana &&
  git config user.email ana@example.test && git add . && git commit -q -m "shop 1.0, two copies")
cd /home/ana/shop/platform

block repo
run 'git log --oneline'
run 'kubectl diff -k shop | grep -E "^[-+] " | head -n 5'
run 'kubectl apply -k shop'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl diff -k shop; echo "diff exit status: $?"'
block change
run "sed -i 's/image: shop:1.0/image: shop:1.1/' shop/deployment.yaml"
run 'git commit -qam "shop 1.1" && git log --oneline'
run 'kubectl diff -k shop | grep -E "^[-+] "'
run 'kubectl apply -k shop'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
block drift
run 'kubectl scale deployment shop --replicas=5'
run 'kubectl diff -k shop | grep -E "^[-+] "'
run 'kubectl apply -k shop'
quiet 'sleep 5'
run 'kubectl get deployment shop'
block revert
run 'git revert --no-edit HEAD >/dev/null && git log --oneline'
run 'kubectl apply -k shop'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image}"; echo'
