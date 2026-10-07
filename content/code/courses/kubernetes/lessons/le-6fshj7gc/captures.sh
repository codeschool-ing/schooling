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
# What is STAGED rather than typed: the cluster (lesson 8's ports.yaml) and a
# busybox pod called `probe`; reading the node's rules with `docker exec`,
# because a kind node is a container; and scaling the shop down to one copy
# before the requests from outside, which the lesson says. The counts per pod come from 300 real
# requests, so they differ on every run, and so do the names and addresses.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
shown "$COURSE/lessons/le-nf7qt63y/the-manifest.md" ports.yaml >/tmp/ports.yaml || exit 1
fresh /tmp/ports.yaml
quiet 'kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600'
shown "$COURSE/lessons/le-6fshj7gc/inside.md" shop.yaml >/tmp/shop.yaml || exit 1
quiet 'kubectl apply -f /tmp/shop.yaml'
quiet 'kubectl rollout status deployment/shop --timeout=120s'
quiet 'kubectl wait --for=condition=Ready pod/probe --timeout=60s'

block mode
run 'kubectl -n kube-system get configmap kube-proxy -o jsonpath="{.data.config\.conf}" | grep "^mode"'
run 'kubectl get service shop -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP'
# kube-proxy writes the rules a moment after the endpoints exist; wait for them.
for _ in $(seq 30); do docker exec shop-worker iptables-save -t nat 2>/dev/null | grep -q 'default/shop ->' && break; sleep 1; done
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
