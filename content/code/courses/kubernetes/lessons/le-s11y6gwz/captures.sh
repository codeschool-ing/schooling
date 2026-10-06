#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, and a busybox pod called `probe`.
#   - the password itself, which is made up for the lab and opens nothing.
#   - turning on encryption at rest. It is a file on the control-plane node and
#     a flag on the API server, written with `docker exec` because the node is
#     a container; on a real control plane it is the same file and the same
#     flag, edited over ssh, and on a managed cluster it is a setting of the
#     provider's. The key is 32 random bytes, generated on the node and never
#     printed. The API server restarts when its manifest changes, and the
#     script waits for it.
# Names and ages differ on every run; the encrypted bytes differ on every write.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
ETCD='kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key'

block create
run 'kubectl create secret generic db --from-literal=user=shop --from-literal=password=lab-only-7Hq2'
run 'kubectl get secret db'
run 'kubectl get secret db -o jsonpath="{.data}"; echo'
run 'kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo'
block use
put shop.yaml <<'CODE'
apiVersion: v1
kind: Pod
metadata:
  name: reader
spec:
  containers:
  - name: reader
    image: busybox:1.37
    command: ["sh", "-c", "sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db
          key: user
    volumeMounts:
    - name: db
      mountPath: /run/secrets/db
      readOnly: true
  volumes:
  - name: db
    secret:
      secretName: db
      defaultMode: 0400
CODE
run 'kubectl apply -f shop.yaml'
quiet 'kubectl wait --for=condition=Ready pod/reader --timeout=90s'
run 'kubectl exec reader -- sh -c '"'"'echo user is $DB_USER; ls -l /run/secrets/db/; mount | grep secrets/db'"'"''
block etcd-plain
run "$ETCD get /registry/secrets/default/db --print-value-only | strings | grep -A1 password"
block encrypt
docker exec shop-control-plane sh -c 'KEY=$(head -c 32 /dev/urandom | base64); cat > /etc/kubernetes/pki/encryption.yaml <<CONF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - secretbox:
      keys:
      - name: key1
        secret: $KEY
  - identity: {}
CONF
chmod 600 /etc/kubernetes/pki/encryption.yaml'
run 'docker exec shop-control-plane sed "s/secret: .*/secret: (32 random bytes, not shown)/" /etc/kubernetes/pki/encryption.yaml'
docker exec shop-control-plane sed -i 's#- --etcd-servers=#- --encryption-provider-config=/etc/kubernetes/pki/encryption.yaml\n    - --etcd-servers=#' /etc/kubernetes/manifests/kube-apiserver.yaml
quiet 'sleep 20'
until kubectl get --raw /readyz >/dev/null 2>&1; do sleep 2; done
quiet 'sleep 5'
run 'docker exec shop-control-plane grep encryption-provider /etc/kubernetes/manifests/kube-apiserver.yaml'
run "$ETCD get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only"
run 'kubectl get secrets --all-namespaces -o json | kubectl replace -f - | tail -n 1'
run "$ETCD get /registry/secrets/default/db --print-value-only | head -c 32; echo"
run "$ETCD get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only"
run 'kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo'
block access
run 'kubectl auth can-i get secrets --as=system:serviceaccount:default:default'
run 'kubectl auth can-i get secrets'
