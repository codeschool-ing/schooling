#!/usr/bin/env bash
# The terminal sessions quoted in lesson 47 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster. kind built it with kubeadm, which is inside every kind
#     node; the lesson runs kubeadm through `docker exec`, because each node
#     is a container. On real machines the same commands run in a shell on
#     each machine.
#   - the join command is the one `kubeadm token create` printed, passed on
#     with --ignore-preflight-errors=all, which is what kind itself does: the
#     recording machine has cgroup v1 and the checks refuse it (see lab.sh).
#   - etcdutl on the control-plane node. It ships inside the etcd image, which
#     has no shell and no `cat` to copy it out with, so the script copies it
#     from the image's unpacked layers under /var/lib/containerd. On a real
#     machine it comes from the etcd release of the same version.
#   - approving the rejoined kubelet's serving certificate (see lab.sh), and
#     the pauses for the node to register, and for the control plane to stop
#     and start again around the restore.
# Tokens, hashes, sizes and times differ on every run; the token was valid
# for 24 hours on a cluster deleted minutes later.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
fresh
approve() {
  for _ in $(seq 30); do
    for c in $(kubectl get csr -o jsonpath='{range .items[?(@.spec.signerName=="kubernetes.io/kubelet-serving")]}{.metadata.name}{" "}{end}'); do
      kubectl certificate approve "$c" >/dev/null 2>&1
    done
    sleep 2
  done
}

block what-kubeadm-made
run 'docker exec shop-control-plane kubeadm version -o short'
run 'docker exec shop-control-plane ls /etc/kubernetes /etc/kubernetes/manifests'
run 'docker exec shop-control-plane kubeadm certs check-expiration | head -n 8'
block remove
run 'kubectl drain shop-worker2 --ignore-daemonsets --delete-emptydir-data'
run 'docker exec shop-worker2 kubeadm reset -f 2>&1 | tail -n 3'
run 'kubectl delete node shop-worker2'
run 'kubectl get nodes'
block join
run 'docker exec shop-control-plane kubeadm token create --print-join-command | tee join.txt'
run "docker exec shop-worker2 $(cat join.txt) --ignore-preflight-errors=all 2>&1 | grep -v '^\[preflight\]\|^W\|^I' | tail -n 6"
approve &
APPROVE=$!
quiet 'kubectl wait --for=condition=Ready node/shop-worker2 --timeout=120s'
run 'kubectl get nodes'
kill "$APPROVE" 2>/dev/null
block etcd
ETCD='etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key'
run "kubectl -n kube-system exec etcd-shop-control-plane -- $ETCD member list -w table"
run 'kubectl create configmap before-backup --from-literal=note=present'
run "kubectl -n kube-system exec etcd-shop-control-plane -- $ETCD snapshot save /var/lib/etcd/snapshot.db"
run 'kubectl -n kube-system exec etcd-shop-control-plane -- etcdutl snapshot status /var/lib/etcd/snapshot.db -w table'
run 'docker cp shop-control-plane:/var/lib/etcd/snapshot.db etcd-snapshot.db && ls -l etcd-snapshot.db'
block restore
run 'kubectl delete configmap before-backup'
quiet "docker exec shop-control-plane sh -c 'cp \"\$(find /var/lib/containerd -path \"*/usr/local/bin/etcdutl\" -type f | head -n 1)\" /usr/local/bin/etcdutl'"
run "docker exec shop-control-plane sh -c 'mkdir -p /root/stopped && mv /etc/kubernetes/manifests/*.yaml /root/stopped/'"
for _ in $(seq 60); do kubectl get --raw /readyz >/dev/null 2>&1 || break; sleep 2; done
sleep 10
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' shop-control-plane)
run "docker exec shop-control-plane etcdutl snapshot restore /var/lib/etcd/snapshot.db --data-dir /var/lib/etcd-restored --name shop-control-plane --initial-cluster shop-control-plane=https://$IP:2380 --initial-advertise-peer-urls https://$IP:2380 2>&1 | tail -n 1"
run "docker exec shop-control-plane sed -i 's#^\\( *\\)path: /var/lib/etcd\$#\\1path: /var/lib/etcd-restored#' /root/stopped/etcd.yaml"
run "docker exec shop-control-plane grep -n 'etcd-restored' /root/stopped/etcd.yaml"
run "docker exec shop-control-plane sh -c 'mv /root/stopped/*.yaml /etc/kubernetes/manifests/'"
for _ in $(seq 90); do kubectl get --raw /readyz >/dev/null 2>&1 && break; sleep 2; done
sleep 5
run 'kubectl get configmap before-backup -o jsonpath="{.data.note}"; echo'
run 'kubectl get nodes'
