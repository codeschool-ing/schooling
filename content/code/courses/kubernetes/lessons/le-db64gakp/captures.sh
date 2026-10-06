#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - two clusters, one after the other. The first is the usual one, with
#     kind's network plugin, kindnet. Kindnet carries a network-policy engine
#     built on nftables, and on the machine this was recorded on the kernel
#     refused it: the engine logged the error and enforced nothing, which the
#     lesson shows. The second cluster is made from lab/cluster-calico.yaml and
#     runs Calico v3.32.1 instead, from Calico's own manifest (lab.sh calico).
#   - the namespaces, the shop and the busybox pods that ask it questions.
# Pod addresses and names differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
setup() {
  kubectl create namespace shop >/dev/null
  kubectl create namespace other >/dev/null
  kubectl -n shop create deployment shop --image=shop:1.0 --replicas=2 >/dev/null
  kubectl -n shop expose deployment shop --port 80 --target-port 8080 >/dev/null
  kubectl -n shop run front --image=busybox:1.37 --labels=app=front --restart=Never --command -- sleep 3600 >/dev/null
  kubectl -n other run stranger --image=busybox:1.37 --restart=Never --command -- sleep 3600 >/dev/null
  kubectl -n shop rollout status deployment/shop --timeout=120s >/dev/null
  kubectl -n shop wait --for=condition=Ready pod/front --timeout=60s >/dev/null
  kubectl -n other wait --for=condition=Ready pod/stranger --timeout=60s >/dev/null
}
fresh
setup

block deny-file
put deny-all.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: shop
spec:
  podSelector: {}
  policyTypes:
  - Ingress
CODE
block kindnet
run 'kubectl get pods -n kube-system -l app=kindnet -o name'
run 'kubectl apply -f deny-all.yaml'
quiet 'sleep 5'
run 'kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop'
run "kubectl -n kube-system logs \$(kubectl -n kube-system get pods -l app=kindnet -o name | head -n 1) | grep -A 1 'syncing nftables'"
fresh "$COURSE/lab/cluster-calico.yaml"
setup

block calico
run 'kubectl get pods -n kube-system -l k8s-app=calico-node -o wide'
run 'kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop'
run 'kubectl apply -f deny-all.yaml'
quiet 'sleep 5'
run 'kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop'
run 'kubectl -n shop exec front -- wget -qO- -T 3 shop'
block allow
put allow-front.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-front
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: front
    ports:
    - port: 8080
CODE
run 'kubectl apply -f allow-front.yaml'
quiet 'sleep 5'
run 'kubectl -n shop exec front -- wget -qO- -T 3 shop'
run 'kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop'
run 'kubectl get networkpolicies -n shop'
block namespace
put allow-monitoring.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
    ports:
    - port: 8080
CODE
run 'kubectl apply -f allow-monitoring.yaml'
run 'kubectl label namespace other purpose=monitoring'
quiet 'sleep 5'
run 'kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop'
block egress
put deny-egress.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-egress
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: shop
    ports:
    - port: 8080
CODE
run 'kubectl apply -f deny-egress.yaml'
quiet 'sleep 5'
run 'kubectl -n shop exec front -- wget -qO- -T 3 shop'
run 'kubectl -n shop exec front -- wget -qO- -T 3 shop.shop.svc.cluster.local'
block dns
put allow-dns.yaml <<'CODE'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-dns
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
CODE
run 'kubectl apply -f allow-dns.yaml'
quiet 'sleep 5'
run 'kubectl -n shop exec front -- wget -qO- -T 3 shop'
run 'kubectl -n shop exec front -- wget -qO- -T 3 http://kubernetes.default:443'
