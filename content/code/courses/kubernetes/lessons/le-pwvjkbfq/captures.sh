#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# A kind node is a Docker container, so "logging in to a node" is
# `docker exec` into it; on a real machine the same commands run over ssh.
#
# What is STAGED rather than typed: the cluster (`fresh`) and the pauses that
# let the rollout finish. Names, addresses, uids and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh

block control-plane
run 'kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=shop-control-plane'
run 'docker exec shop-control-plane ls /etc/kubernetes/manifests'
run 'docker exec shop-control-plane grep -E "^ +- --(etcd-servers|secure-port|service-cluster-ip-range)" /etc/kubernetes/manifests/kube-apiserver.yaml'
block etcd
quiet 'kubectl create deployment web --image=shop:1.0 --replicas=2'
quiet 'kubectl rollout status deployment/web --timeout=120s'
ETCD='kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key'
run "$ETCD get /registry/deployments/default --prefix --keys-only"
run "$ETCD get /registry/pods/default --prefix --keys-only"
block node
run 'docker exec shop-worker systemctl is-active containerd kubelet'
run 'docker exec shop-worker2 crictl ps -o table'
run 'docker exec shop-worker ls /etc/cni/net.d'
block events
quiet 'kubectl delete deployment web'
quiet 'sleep 5'
quiet 'kubectl delete events --all'
run 'kubectl create deployment shop --image=shop:1.0'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'sleep 2'
run 'kubectl get events --sort-by=.metadata.resourceVersion -o custom-columns=SOURCE:.source.component,REASON:.reason,OBJECT:.involvedObject.kind,MESSAGE:.message'
block apiserver-down
run 'docker exec shop-control-plane mv /etc/kubernetes/manifests/kube-scheduler.yaml /root/'
quiet 'sleep 25'
run 'kubectl get pods -n kube-system -l component=kube-scheduler'
run 'kubectl scale deployment shop --replicas=3'
quiet 'sleep 5'
run 'kubectl get pods -l app=shop'
run 'docker exec shop-control-plane mv /root/kube-scheduler.yaml /etc/kubernetes/manifests/'
quiet 'sleep 30'
run 'kubectl get pods -l app=shop -o wide'
