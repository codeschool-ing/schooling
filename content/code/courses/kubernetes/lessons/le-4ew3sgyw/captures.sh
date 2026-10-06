#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster, a busybox pod called `probe`
# that asks the shop questions from inside the cluster (the shop's image has
# no shell), and the pauses: the kubelet refreshes a mounted ConfigMap on its
# own schedule, so the script waits and asks again. How long that took is
# printed by the script itself. Names and ages differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block create
run 'kubectl create configmap shop-config --from-literal=GREETING="Ana'"'"'s shop" --from-literal=CURRENCY=BRL'
put greeting.txt <<'CODE'
Welcome back. Orders placed before 18:00 ship today.
CODE
run 'kubectl create configmap shop-files --from-file=greeting=greeting.txt'
run 'kubectl get configmaps'
run 'kubectl get configmap shop-config -o yaml | head -n 6'
block use
put shop.yaml <<'CODE'
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
        env:
        - name: GREETING
          valueFrom:
            configMapKeyRef:
              name: shop-config
              key: GREETING
        envFrom:
        - prefix: SHOP_
          configMapRef:
            name: shop-config
        volumeMounts:
        - name: files
          mountPath: /etc/shop
          readOnly: true
      volumes:
      - name: files
        configMap:
          name: shop-files
---
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
run 'kubectl apply -f shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
run 'kubectl exec probe -- wget -qO- shop/config'
run 'kubectl exec probe -- wget -qO- shop/'
block update
put greeting.txt <<'CODE'
Closed for stocktaking on Sunday.
CODE
run 'kubectl create configmap shop-files --from-file=greeting=greeting.txt --dry-run=client -o yaml | kubectl apply -f -'
run 'kubectl create configmap shop-config --from-literal=GREETING="Ana'"'"'s new shop" --from-literal=CURRENCY=BRL --dry-run=client -o yaml | kubectl apply -f -'
run 'kubectl exec probe -- wget -qO- shop/config'
SECONDS=0
until kubectl exec probe -- wget -qO- shop/config 2>/dev/null | grep -q stocktaking; do sleep 2; done
block waited
echo "##### the file changed after about $SECONDS seconds"
run 'kubectl exec probe -- wget -qO- shop/config'
block restart
run 'kubectl rollout restart deployment/shop'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
run 'kubectl exec probe -- wget -qO- shop/config'
block immutable
put frozen.yaml <<'CODE'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prices-2026-10
immutable: true
data:
  shipping: "19.90"
CODE
run 'kubectl apply -f frozen.yaml'
run 'kubectl patch configmap prices-2026-10 -p '"'"'{"data":{"shipping":"0.00"}}'"'"''
