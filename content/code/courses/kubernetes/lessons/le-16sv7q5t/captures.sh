#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, made from lab/cluster-ports.yaml so the laptop's 8080
#     reaches the NodePort, and a busybox pod called `probe`.
#   - cloud-provider-kind, started on the laptop in the background. It is
#     the kind project's stand-in for a cloud's load balancer: it watches for
#     Services of type LoadBalancer and answers each with an Envoy container
#     on Docker's network, whose address it writes into the Service. A cloud
#     does the same with a machine of its own.
# ClusterIPs, pod addresses, the load balancer's address and pod names differ
# on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh "$COURSE/lab/cluster-ports.yaml"
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'

block clusterip
put shop.yaml <<'CODE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
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
        ports:
        - name: http
          containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - name: http
    port: 80
    targetPort: http
CODE
run 'kubectl apply -f shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'
run 'kubectl get service shop'
run 'kubectl get endpointslices -l kubernetes.io/service-name=shop'
run 'kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,IP:.status.podIP'
block dns
run 'kubectl exec probe -- cat /etc/resolv.conf'
run 'kubectl exec probe -- nslookup shop'
run 'kubectl exec probe -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- shop; done"'
block empty
run 'kubectl scale deployment shop --replicas=0'
quiet 'sleep 5'
run 'kubectl get endpointslices -l kubernetes.io/service-name=shop'
run 'kubectl exec probe -- wget -qO- -T 3 shop'
run 'kubectl scale deployment shop --replicas=3'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
block nodeport
put shop-nodeport.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: shop-nodeport
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
    nodePort: 30080
CODE
run 'kubectl apply -f shop-nodeport.yaml'
run 'kubectl get service shop-nodeport'
run 'kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address'
quiet 'sleep 2'
CP=$(kubectl get node shop-worker -o jsonpath='{.status.addresses[0].address}')
run "curl -s $CP:30080; curl -s localhost:8080"
block loadbalancer
cloud-provider-kind >/tmp/cpk.log 2>&1 </dev/null & CPK=$!
put shop-lb.yaml <<'CODE'
apiVersion: v1
kind: Service
metadata:
  name: shop-lb
spec:
  type: LoadBalancer
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
CODE
run 'kubectl apply -f shop-lb.yaml'
for _ in $(seq 60); do [ -n "$(kubectl get svc shop-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" ] && break; sleep 2; done
quiet 'sleep 5'
run 'kubectl get service shop-lb'
LB=$(kubectl get svc shop-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
run "curl -s $LB"
run 'docker ps --filter label=io.x-k8s.cloud-provider-kind.cluster=shop --format "{{.Names}}\t{{.Image}}"'
run 'kubectl delete service shop-lb'
quiet 'sleep 5'
kill "$CPK"; wait "$CPK" 2>/dev/null
