---
title: A cluster of your own
version: 1
---

The rest of the course happens on a cluster, and this is the one: **three nodes made of Docker
containers, built by `kind` from a file of a dozen lines.** Lesson 5 opens it up and compares `kind`
with the other ways of having a cluster on a laptop; here it only has to exist. Two more files go
into `~/shop`.

`cluster.yaml`, the cluster:

```yaml
# The cluster the lessons run on: one control-plane node and two workers.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this course was recorded on, which
# has cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
  serverTLSBootstrap: true
nodes:
- role: control-plane
- role: worker
- role: worker
```

The three `nodes` are what matters: one control plane and two workers, so that scheduling, spreading
and losing a node all have somewhere to happen. `serverTLSBootstrap: true` makes each node's kubelet
ask the cluster for a proper certificate instead of signing its own, which lesson 21 needs. **The two
patches above it are not part of the lesson.** The machine this course was recorded on has cgroup v1
and forbids lowering a process's OOM score. A current Ubuntu, Docker Desktop or WSL 2 has neither
restriction, so delete those lines on yours and leave `serverTLSBootstrap: true` where it is.

`up.sh`, which throws away whatever cluster was there and builds a fresh one:

```sh
#!/bin/sh
# A fresh cluster called shop, with the shop's images inside it.
#   ./up.sh               the three nodes of cluster.yaml
#   ./up.sh other.yaml    another kind configuration, when a lesson asks
set -e
cd "$(dirname "$0")"
config=${1:-cluster.yaml}
kind delete cluster --name shop
kind create cluster --name shop --config "$config" --quiet
# The nodes are containers with an image store of their own, and they cannot
# see what Docker built on this machine. Copy the shop in.
kind load docker-image shop:1.0 shop:1.1 shop:2.0 --name shop
# Each kubelet asks the cluster for a serving certificate (serverTLSBootstrap
# in cluster.yaml). Wait for one request per node, then approve them.
nodes=$(kubectl get nodes --no-headers | wc -l)
until [ "$(kubectl get csr --no-headers | grep -c kubelet-serving)" -ge "$nodes" ]; do
  sleep 2
done
kubectl get csr --no-headers | awk '/kubelet-serving/ && /Pending/ {print $1}' |
  xargs -r kubectl certificate approve
# A cluster made without kind's network plugin (lesson 24) has no Ready node
# until one is installed, so there is nothing to wait for yet.
grep -q 'disableDefaultCNI: true' "$config" && exit 0
kubectl wait --for=condition=Ready nodes --all --timeout=180s
```

```
ana@laptop:~/shop$ chmod +x up.sh
ana@laptop:~/shop$ ./up.sh
Deleting cluster "shop" ...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker2", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-worker", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-control-plane", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-worker2", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-worker", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-control-plane", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-worker2", loading...
certificatesigningrequest.certificates.k8s.io/csr-2cc6w approved
certificatesigningrequest.certificates.k8s.io/csr-cwz5v approved
certificatesigningrequest.certificates.k8s.io/csr-fvgh2 approved
certificatesigningrequest.certificates.k8s.io/csr-vgj84 approved
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
```

Read from the top. The old cluster is deleted; there was none the first time, and deleting nothing
is not an error. The new one is created, with `--quiet` keeping kind's list of steps to itself
(lesson 5 names them). Then the shop's three images go into each of the three nodes, one
certificate request per node is approved, and every node is `Ready`. **The images have to
be copied because a node is a container with its own image store**: it cannot see what Docker built
on the machine around it, and it would look for `shop:1.0` on Docker Hub and not find it. The last
section of this lesson shows exactly that going wrong.

```
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   28s   v1.37.0
shop-worker          Ready    <none>          13s   v1.37.0
shop-worker2         Ready    <none>          13s   v1.37.0
```

**Every lesson from lesson 2 on starts with `./up.sh`**, and its transcripts begin on a cluster made
that way, so that no lesson depends on what the one before it left behind. A lesson that needs a
different cluster, or something installed into it, says so before its first command. When you stop
for the day, `kind delete cluster --name shop` gives back the memory.
