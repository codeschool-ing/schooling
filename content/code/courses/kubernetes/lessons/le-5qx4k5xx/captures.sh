#!/usr/bin/env bash
# The terminal sessions quoted in lesson 38 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, and the pauses that let pods
# start. Kustomize is the copy built into kubectl. Names and ages differ on
# every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
rm -rf /home/ana/shop/deploy

block base
put deploy/base/deployment.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
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
        envFrom:
        - configMapRef:
            name: shop-settings
CODE
put deploy/base/service.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
CODE
put deploy/base/kustomization.yaml <<'CODE'
resources:
- deployment.yaml
- service.yaml
configMapGenerator:
- name: shop-settings
  literals:
  - GREETING=hello
CODE
block overlays
put deploy/overlays/staging/kustomization.yaml <<'CODE'
resources:
- ../../base
namespace: staging
nameSuffix: -staging
labels:
- pairs:
    env: staging
configMapGenerator:
- name: shop-settings
  behavior: merge
  literals:
  - GREETING=staging
CODE
put deploy/overlays/production/kustomization.yaml <<'CODE'
resources:
- ../../base
namespace: production
labels:
- pairs:
    env: production
images:
- name: shop
  newTag: "1.1"
patches:
- path: replicas.yaml
CODE
put deploy/overlays/production/replicas.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
CODE
run 'find deploy -type f | sort'
block build
run 'kubectl kustomize deploy/overlays/production | grep -E "^kind|^  name|namespace:|replicas|image:|env:"'
run 'kubectl kustomize deploy/overlays/staging | grep -E "^kind|^  name|namespace:|GREETING|name: shop-settings"'
block apply
run 'kubectl create namespace staging && kubectl create namespace production'
run 'kubectl apply -k deploy/overlays/staging'
run 'kubectl apply -k deploy/overlays/production'
quiet 'kubectl -n staging rollout status deployment/shop-staging --timeout=120s'
quiet 'kubectl -n production rollout status deployment/shop --timeout=120s'
run 'kubectl get deployments -A -l env -L env'
block change
run "sed -i 's/GREETING=hello/GREETING=welcome/' deploy/base/kustomization.yaml"
run 'kubectl diff -k deploy/overlays/production | grep -E "^[-+] " | head -n 12'
run 'kubectl apply -k deploy/overlays/production'
quiet 'kubectl -n production rollout status deployment/shop --timeout=120s'
run 'kubectl -n production get configmaps'
