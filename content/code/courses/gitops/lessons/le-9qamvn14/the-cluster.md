---
title: A cluster, a registry and the tools
version: 1
---

**Every lesson of this course runs against the same small setup**, and this section builds it: a
Kubernetes cluster made by `kind`, an image registry beside it, and the two programs that drive
them. Lesson 2 adds a Git server, and each later lesson installs the one tool it is about.

## Docker

The `docker` course installs Docker Engine in lesson 6, from Docker's own package repository. If
you did that course on this machine, skip ahead. The short version, from Docker's installation
instructions for Ubuntu, is:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

The last line lets you use `docker` without `sudo`, from your next login. **These commands were not
run for this course**, because the recording machine already had Docker. This is the version it
has:

```
ana@laptop:~/setup$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
```

## kind and kubectl

The transcripts were recorded as `ana`, on a machine called `laptop`. Make a directory for the
files of this setup with `mkdir ~/setup && cd ~/setup`. Your prompt will show your own user and
machine, and that is the only difference you should see.

Both programs are single files, downloaded from their projects and checked against the checksum
each project publishes beside the file. `ARCH` is `amd64` on most computers and `arm64` on an
Apple-silicon Mac, and `dpkg` knows which:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture); echo $ARCH
amd64
ana@laptop:~/setup$ curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check
kind: OK
ana@laptop:~/setup$ curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl
ana@laptop:~/setup$ echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check
kubectl: OK
ana@laptop:~/setup$ sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl
ana@laptop:~/setup$ kind version
kind v0.33.0 go1.26.7 linux/amd64
ana@laptop:~/setup$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

**The two `OK`s are the reason for the middle lines**: the file you downloaded is the file the
project published. A failed check prints `FAILED` and exits with an error, and the right response
is to delete the file and download it again, never to install it anyway. Lesson 8 comes back to
this habit and asks what a checksum proves and what it does not.

## The registry

GitOps deploys **images that already exist**, by name. Something has to hold them where the
cluster can pull them, so the setup gets its own registry: the reference implementation of the
OCI distribution protocol, run as a container, listening only on your own machine.

```sh
docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 registry:3.1.2
```

```
ana@laptop:~/setup$ docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 registry:3.1.2
15cda3b455ca5ccbee1f6be74339f4d5698f3f50dcb23014b9d39bff7fab31c5
ana@laptop:~/setup$ curl -s localhost:5001/v2/_catalog
{"repositories":[]}
```

An empty catalogue is the right answer: the registry is up and holds nothing yet. Port 5001 on
your side becomes 5000 inside the container, and `127.0.0.1` keeps it off your network. Lesson 7
is about registries; for now it is a place to put one image.

## The cluster

A cluster is described in a file, like everything else here. Save this one as
`~/setup/cluster.yaml`:

```yaml
# The study cluster for gitops: one node, two ports reachable from your
# computer, and a registry it can pull from.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
# Read registry settings from /etc/containerd/certs.d, where the commands
# after this file tell the node where localhost:5001 really is.
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
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
  - containerPort: 30080   # staging's bulletin
    hostPort: 8080
    listenAddress: 127.0.0.1
  - containerPort: 30081   # production's bulletin
    hostPort: 8081
    listenAddress: 127.0.0.1
```

**One node is enough**, because nothing in this course is about scheduling: it is about how a
change reaches the cluster. The two `extraPortMappings` make ports 8080 and 8081 on your machine
lead to the node, so an application published there answers `curl` without a port-forward. The
first patch is the one that matters for the registry, and the next commands use it.

```
ana@laptop:~/setup$ time kind create cluster --name gitops --config cluster.yaml --quiet

real	0m16.115s
user	0m1.663s
sys	0m1.481s
ana@laptop:~/setup$ kind get clusters
gitops
ana@laptop:~/setup$ kubectl config current-context
kind-gitops
```

**Sixteen seconds**, most of it the node starting its own containers. kind wrote a context called
`kind-gitops` into `~/.kube/config` and made it the current one, which is why `kubectl` knows where
to go.

## Teaching the node where the registry is

There is a catch in the name `localhost:5001`. On your machine it means the registry. **Inside the
node it means the node itself**, where nothing listens on 5001. So the node is told, in the
directory the first patch pointed at, that `localhost:5001` is really the container called
`registry` on port 5000, and the registry joins the network the node is on:

```sh
for node in $(kind get nodes --name gitops); do
  docker exec "$node" mkdir -p /etc/containerd/certs.d/localhost:5001
  printf '[host."http://registry:5000"]\n' |
    docker exec -i "$node" cp /dev/stdin /etc/containerd/certs.d/localhost:5001/hosts.toml
done
docker network connect kind registry
```

This is the arrangement kind's own documentation recommends for a local registry, and it means
one image name works in both places: you push `localhost:5001/bulletin:1.0` from your terminal, and
a manifest naming `localhost:5001/bulletin:1.0` is pulled by the node from the same registry.

```
ana@laptop:~/setup$ kubectl get nodes
NAME                   STATUS   ROLES           AGE   VERSION
gitops-control-plane   Ready    control-plane   23s   v1.37.0
```

`Ready`, on Kubernetes `v1.37.0`. The setup is complete. `kind delete cluster --name gitops` gives
back everything the cluster uses, and `docker rm -f registry` the registry; the next section puts
something in them.
