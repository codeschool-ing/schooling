---
title: Four ways it fails on the first day
version: 1
---

**When a local cluster will not start, the error is almost never about Kubernetes.** It is about
the machine underneath: a name already taken, a Docker that is not answering, a port somebody else
holds, a `kubectl` pointed at a cluster that is gone. Each of the four below was produced on purpose
on the laptop, and each has a fix of one line.

## The name is taken

Running the same command twice:

```
ana@laptop:~/shop$ kind create cluster --name study --config cluster.yaml
cgroup v1 is deprecated in Kubernetes and will not be supported in a future kind release, please upgrade to cgroup v2
ERROR: failed to create cluster: node(s) already exist for a cluster with the name "study"
```

**A kind cluster is named, and the name must be free.** The first line is a warning this machine
prints because of its cgroup v1, and you will not see it on yours. The error is the second line:
`study` already exists. Either use it, pick another name with `--name`, or remove it with
`kind delete cluster --name study` and start again.

## Docker is not answering

The nodes are containers, so kind needs a Docker daemon before it can do anything. Here the client
was pointed at a socket nothing listens on, which is exactly what it sees when Docker is stopped:

```
ana@laptop:~/shop$ DOCKER_HOST=unix:///run/nothing.sock kind create cluster --name other 2>&1 | tail -n 1
failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

The message names the socket and suggests the cause. On Linux, `sudo systemctl start docker`; with
Docker Desktop, open it and wait until it says it is running. If `docker ps` works and kind still
says this, the variable `DOCKER_HOST` or a Docker context is pointing somewhere else.

## A port is held by something else

A cluster that publishes a node's port on the laptop — so that a browser can reach a Service, as
lesson 8 does — needs that port free. This file asks for the laptop's 8080, which a small web server
was already holding:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
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
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
```

```
ana@laptop:~/shop$ kind create cluster --name ports --config ports.yaml 2>&1 | grep -o "failed to bind host port.*"
failed to bind host port 0.0.0.0:8080/tcp: address already in use
```

**It is Docker's error, passed through kind**, and it says which port. Find what holds it — `sudo
lsof -i :8080` or `sudo ss -ltnp` on Linux — and stop it, or change `hostPort` to a port nobody
uses. A failed `kind create` leaves nothing behind that needs cleaning.

## kubectl is pointed at nothing

Deleting a cluster removes its context from `~/.kube/config`, and if it was the current one,
`kubectl` is left with no context at all:

```
ana@laptop:~/shop$ kind delete cluster --name study
Deleting cluster "study" ...
Deleted nodes: ["study-control-plane" "study-worker" "study-worker2"]
ana@laptop:~/shop$ kubectl get nodes
E1006 13:37:53.979359   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.979744   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.981892   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.982304   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.983883   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
The connection to the server localhost:8080 was refused - did you specify the right host or port?
ana@laptop:~/shop$ kubectl config current-context
error: current-context is not set
```

**This error is the most misleading of the four.** With no context, `kubectl` falls back to an old
default, an unencrypted API server on `localhost:8080`, which nothing on a modern machine provides.
The fix is to point it at a cluster that exists: `kubectl config get-contexts` lists them, and
`kubectl config use-context kind-shop` picks one.

| what you see | what it means | the fix |
|---|---|---|
| `node(s) already exist for a cluster with the name` | the name is taken | use it, or `kind delete cluster --name …` |
| `failed to connect to the docker API` | Docker is not running, or not where the client looks | start Docker; check `DOCKER_HOST` |
| `failed to bind host port … address already in use` | a port in `extraPortMappings` is held | free the port or change `hostPort` |
| `The connection to the server localhost:8080 was refused` | `kubectl` has no current context | `kubectl config use-context …` |

One more failure has no clean message: **a cluster that starts and then loses nodes, or pods that
are killed for no visible reason, usually means Docker has too little memory.** Docker Desktop runs
its containers inside a virtual machine with a fixed size; give it at least 4 GiB in its settings
before blaming the cluster. Lesson 19 shows what a container killed for memory looks like.
