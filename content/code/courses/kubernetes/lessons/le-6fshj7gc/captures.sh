#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster (lab/cluster-ports.yaml) and a
# busybox pod called `probe`; reading the node's rules with `docker exec`,
# because a kind node is a container. The counts per pod come from 300 real
# requests, so they differ on every run, and so do the names and addresses.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh "$COURSE/lab/cluster-ports.yaml"
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'
cat >/tmp/shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 3
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Service
metadata: {name: shop}
spec: {selector: {app: shop}, ports: [{port: 80, targetPort: 8080}]}
CODE
quiet 'kubectl apply -f /tmp/shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'

block mode
run 'kubectl -n kube-system get configmap kube-proxy -o jsonpath="{.data.config\.conf}" | grep "^mode"'
run 'kubectl get service shop -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP'
SVC=$(kubectl get svc shop -o jsonpath='{.spec.clusterIP}')
run "docker exec shop-worker iptables-save -t nat | grep -E 'KUBE-SVC.*default/shop' | grep -v KUBE-MARK"
block spread
run 'kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c'
block affinity
run 'kubectl patch service shop -p '"'"'{"spec":{"sessionAffinity":"ClientIP"}}'"'"''
quiet 'sleep 3'
run 'kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c'
run 'kubectl patch service shop -p '"'"'{"spec":{"sessionAffinity":"None"}}'"'"''
block outside
put shop-public.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  externalTrafficPolicy: Cluster
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
CODE
run 'kubectl apply -f shop-public.yaml'
quiet 'kubectl scale deployment shop --replicas=1'
quiet 'sleep 6'
run 'kubectl get pods -l app=shop -o wide'
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address'
NODES=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[0].address}{" "}{end}')
run "for ip in $NODES; do echo -n \"\$ip: \"; curl -s -m 2 \$ip:30080 || echo no answer; done"
run 'kubectl logs deployment/shop --tail=3'
block local
run 'kubectl patch service shop-public -p '"'"'{"spec":{"externalTrafficPolicy":"Local"}}'"'"''
quiet 'sleep 4'
run "for ip in $NODES; do echo -n \"\$ip: \"; curl -s -m 2 \$ip:30080 || echo no answer; done"
run 'kubectl logs deployment/shop --tail=1'
