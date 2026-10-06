#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the cluster; and saving the cluster's CA
# certificate and API server address into files for curl, which the lesson
# describes and does not show. The tokens are short-lived (ten minutes) and
# were never printed. Port numbers, names and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' > server.txt

block whoami
run 'kubectl auth whoami'
run 'kubectl get clusterrolebinding kubeadm:cluster-admins -o custom-columns=ROLE:.roleRef.name,SUBJECT:.subjects[0].name'
block serviceaccount
run 'kubectl create namespace shop'
run 'kubectl create serviceaccount deployer -n shop'
run 'kubectl auth can-i list pods -n shop --as=system:serviceaccount:shop:deployer'
run 'TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 8'
block role
put deployer-role.yaml <<'CODE'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: shop
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer
  namespace: shop
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: shop
CODE
run 'kubectl apply -f deployer-role.yaml'
run 'TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 6'
block can-i
SA=system:serviceaccount:shop:deployer
for q in 'create deployments -n shop' 'delete deployments -n shop' 'get secrets -n shop' 'list pods -n default' 'create pods/exec -n shop'; do
  run "kubectl auth can-i $q --as=$SA"
done
run "kubectl auth can-i --list -n shop --as=$SA | head -n 8"
block use-it
run "kubectl --as=$SA -n shop create deployment shop --image=shop:1.0"
run "kubectl --as=$SA -n shop delete deployment shop"
block in-pod
put reader.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: reader
  namespace: shop
spec:
  serviceAccountName: deployer
  automountServiceAccountToken: true
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
CODE
run 'kubectl apply -f reader.yaml'
quiet 'kubectl -n shop wait --for=condition=Ready pod/reader --timeout=60s'
run 'kubectl -n shop exec reader -- ls /var/run/secrets/kubernetes.io/serviceaccount'
run 'kubectl -n shop exec reader -- sh -c "cut -d. -f2 /var/run/secrets/kubernetes.io/serviceaccount/token | base64 -d 2>/dev/null | head -c 400"; echo'
block clusterroles
run 'kubectl get clusterroles view edit admin cluster-admin'
run 'kubectl get clusterroles --no-headers | wc -l'
