---
title: A three-node cluster with kind
version: 1
---

Three programs are all the lab needs: Docker, which runs the nodes, `kind`, which builds the
cluster, and `kubectl`, which talks to it. These are the versions every transcript in the course was
recorded with:

```
ana@laptop:~/shop$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@laptop:~/shop$ kind version
kind v0.33.0 go1.24.7 linux/amd64
ana@laptop:~/shop$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

`kubectl` installs on its own from the Kubernetes project's downloads, and kind is a single binary
from its release page or a package manager. **Keep `kubectl` within one minor version of the
cluster**: 1.37 against a cluster of 1.37 here, which the project guarantees to work, while a gap of
two versions is not supported.

## The cluster, written down

A cluster is described in a file, like everything else in this course:

```yaml
# A study cluster: one control-plane node and two workers.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
- role: worker
```

The three `nodes` are what matters: one control plane and two workers, so that scheduling, spreading
and losing a node all have somewhere to happen. The two patches above them are not part of the
lesson. The machine this course was recorded on has cgroup v1 and forbids lowering a process's OOM
score; yours, on any current Linux, Docker Desktop or WSL 2, has neither restriction, and the file
works without those eight lines.

```
ana@laptop:~/shop$ time kind create cluster --name study --config cluster.yaml --quiet

real	0m23.864s
user	0m2.066s
sys	0m1.678s
ana@laptop:~/shop$ kind get clusters
study
ana@laptop:~/shop$ kubectl config current-context
kind-study
```

**Twenty-four seconds** for three nodes, timed by the shell. `--quiet` only hides kind's progress
list: without it kind prints one line per step, from *Ensuring node image* and *Preparing nodes* to
*Installing CNI*, *Installing StorageClass* and *Joining worker nodes*. kind also wrote a context
called `kind-study` into `~/.kube/config` and made it the current one, which is why `kubectl` knows
where to go without being told; lesson 7 is about that file.

```
ana@laptop:~/shop$ kubectl get nodes -o wide
NAME                  STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION           CONTAINER-RUNTIME
study-control-plane   Ready    control-plane   28s   v1.37.0   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
study-worker          Ready    <none>          13s   v1.37.0   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
study-worker2         Ready    <none>          13s   v1.37.0   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
```

All three are `Ready`, on Kubernetes `v1.37.0`, with containerd as the runtime. The `KERNEL-VERSION`
column is the laptop's own kernel: **a container shares the kernel of the machine it runs on**, so
these nodes are three sets of processes on one Linux, and that is the whole reason they start in
seconds.

## What the cluster is made of, and what it costs

From Docker's side, a node is a container like any other:

```
ana@laptop:~/shop$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES                 IMAGE                  STATUS
study-control-plane   kindest/node:v1.37.0   Up 34 seconds
study-worker          kindest/node:v1.37.0   Up 34 seconds
study-worker2         kindest/node:v1.37.0   Up 34 seconds
```

And it costs what its processes use, measured after the cluster had settled for twenty seconds:

```
ana@laptop:~/shop$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
NAME                  CPU %     MEM USAGE / LIMIT
study-control-plane   12.87%    537.5MiB / 15.72GiB
study-worker          1.77%     121MiB / 15.72GiB
study-worker2         1.87%     120.5MiB / 15.72GiB
```

**About 780 MiB for the whole cluster**: 537.5 for the control-plane node, which runs etcd and the
API server, and about 120 for each worker. The CPU column is a snapshot of one moment; an idle
cluster spends most of its CPU on the control plane checking itself. On a laptop with 8 GiB this
leaves room for everything the course runs, and `kind delete cluster` gives all of it back.
