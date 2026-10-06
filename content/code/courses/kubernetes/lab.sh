#!/usr/bin/env bash
# The laptop every transcript in this course was recorded on, and the clusters
# it runs.
#
# EVERY CLUSTER IN THIS COURSE IS REAL, AND NONE OF IT IS IN A CLOUD. A cluster
# is kind: each "node" is a Docker container running systemd, containerd and the
# kubelet, and the control plane inside the first one is the kube-apiserver,
# etcd, the scheduler and the controller manager that kubeadm installs on a
# real machine, at the version Kubernetes released. What kind leaves out is
# hardware: three nodes share one laptop's CPU and memory.
#
#   sudo bash lab.sh tools          # once: the software and images, into /opt/k8s
#   sudo bash lab.sh up [CONFIG]    # a fresh cluster "shop" (CONFIG: a kind config)
#   sudo bash lab.sh load IMAGE...  # copy images from the laptop into every node
#   sudo bash lab.sh down           # delete every cluster this lab made
#
# WHAT IS STAGED, and why. The machine this was recorded on could reach
# dl.k8s.io, the Go module proxy, raw.githubusercontent.com and Docker Hub
# (through Google's mirror, mirror.gcr.io), and NOT registry.k8s.io, quay.io or
# GitHub's release downloads. So:
#   - kubectl comes from dl.k8s.io, checked against its published SHA256.
#   - kind, helm, metrics-server, cloud-provider-kind and the other Kubernetes
#     programs below are built from their released source with the Go
#     toolchain, at the tags pinned here. The ones that run INSIDE the cluster
#     are wrapped in an image of their own, tagged lab.local/NAME:VERSION, so a
#     `kubectl describe` never claims an image came from a registry it did not.
#   - the nodes never pull anything. Every image a lesson runs is pulled once
#     onto the laptop and copied into the nodes (`lab.sh load`, which is
#     `kind load`), and the manifests ask for it by tag. On your own computer the
#     nodes pull for themselves and none of this is needed.
#   - the shop application is lab/shop, built here, three versions of it.
#
# Two settings differ from kind's defaults, both because of the sandbox and not
# because of anything a lesson teaches. The machine has cgroup v1, which the
# kubelet refuses since 1.35 unless told `failCgroupV1: false`; and the sandbox
# forbids lowering a process's OOM score, so containerd is told to keep
# containers' scores at or above its own (`restrict_oom_score_adj`). On a
# machine with cgroup v2, which is every current Linux distribution and Docker
# Desktop, neither line is needed.
#
# One setting differs on purpose: `serverTLSBootstrap: true` makes each kubelet
# ask the cluster's CA for its serving certificate, so metrics-server can verify
# it (lesson 21 approves them). kind's default leaves the kubelets with
# self-signed certificates, and the usual workaround is a flag that turns the
# verification off.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

OPT=/opt/k8s
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KUBECTL=v1.37.1
KIND=v0.33.0
NODE=kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
HELM=v4.3.0
METRICS_SERVER=v0.9.0
CLOUD_PROVIDER_KIND=v0.12.0
CALICO=v3.32.1
# Images every cluster gets on creation. A lesson that needs more loads them.
BASE_IMAGES="shop:1.0 shop:1.1 shop:2.0 busybox:1.37 nginx:1.29"
export PATH=$OPT/bin:$PATH
export KUBECONFIG=${KUBECONFIG:-/home/ana/.kube/config}

docker_up() { # the Docker daemon, with Hub reached through Google's mirror
  docker info >/dev/null 2>&1 && return 0
  mkdir -p /etc/docker
  [ -f /etc/docker/daemon.json ] || echo '{"registry-mirrors":["https://mirror.gcr.io"]}' >/etc/docker/daemon.json
  setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
  for _ in $(seq 60); do docker info >/dev/null 2>&1 && return 0; sleep 1; done
  echo "dockerd did not start; see /var/log/dockerd.log" >&2; return 1
}

pull() { # IMAGE: from Docker Hub, retried, because the mirror answers 429 under load
  docker image inspect "$1" >/dev/null 2>&1 && return 0
  for i in 1 2 3 4 5 6; do docker pull -q "$1" >/dev/null && return 0; sleep $((i * 15)); done
  echo "could not pull $1" >&2; return 1
}

gobuild() { # MODULE@VERSION PACKAGE NAME [LDFLAGS]: built inside its own module
  local mv=$1 pkg=$2 name=$3 ld=${4:-} dir
  [ -x "$OPT/bin/$name" ] && return 0
  dir=$(GOTOOLCHAIN=auto GOFLAGS=-mod=mod go mod download -json "$mv" | jq -r .Dir)
  rm -rf "$OPT/src/$name" && mkdir -p "$OPT/src" && cp -r "$dir" "$OPT/src/$name" && chmod -R u+w "$OPT/src/$name"
  (cd "$OPT/src/$name" && GOTOOLCHAIN=auto GOFLAGS=-mod=mod CGO_ENABLED=0 go build -trimpath -ldflags "$ld" -o "$OPT/bin/$name" "$pkg")
}

wrap() { # NAME VERSION BINARY [ARGS-AS-JSON]: one static binary as an image of its own
  local name=$1 version=$2 bin=$3 dir
  docker image inspect "lab.local/$name:$version" >/dev/null 2>&1 && return 0
  dir=$(mktemp -d) && cp "$bin" "$dir/$name"
  printf 'FROM scratch\nCOPY %s /%s\nUSER 65532:65532\nENTRYPOINT ["/%s"]\n' "$name" "$name" "$name" >"$dir/Dockerfile"
  docker build -q -t "lab.local/$name:$version" "$dir" >/dev/null && rm -rf "$dir"
}

shop_images() { # the course's own application, three versions
  local v dir
  for v in 1.0 1.1 2.0; do
    docker image inspect "shop:$v" >/dev/null 2>&1 && continue
    dir=$(mktemp -d)
    (cd "$LAB/lab/shop" && GOTOOLCHAIN=local CGO_ENABLED=0 go build -trimpath \
      -ldflags "-X main.version=$v" -o "$dir/shop" .)
    cp "$LAB/lab/shop/Dockerfile" "$dir/"
    docker build -q -t "shop:$v" "$dir" >/dev/null && rm -rf "$dir"
  done
}

tools() {
  docker_up
  mkdir -p "$OPT/bin" "$OPT/manifests"
  if [ ! -x "$OPT/bin/kubectl" ]; then
    curl -sSfLo "$OPT/bin/kubectl" "https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl"
    echo "$(curl -sSfL "https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl.sha256")  $OPT/bin/kubectl" | sha256sum -c --quiet
    chmod +x "$OPT/bin/kubectl"
  fi
  gobuild "sigs.k8s.io/kind@$KIND" . kind
  gobuild "helm.sh/helm/v4@$HELM" ./cmd/helm helm "-X helm.sh/helm/v4/internal/version.version=$HELM"
  gobuild "sigs.k8s.io/metrics-server@$METRICS_SERVER" ./cmd/metrics-server metrics-server \
    "-X sigs.k8s.io/metrics-server/pkg/version.gitVersion=$METRICS_SERVER"
  gobuild "sigs.k8s.io/cloud-provider-kind@$CLOUD_PROVIDER_KIND" . cloud-provider-kind
  wrap metrics-server "$METRICS_SERVER" "$OPT/bin/metrics-server"
  [ -f "$OPT/manifests/calico.yaml" ] || curl -sSfo "$OPT/manifests/calico.yaml" \
    "https://raw.githubusercontent.com/projectcalico/calico/$CALICO/manifests/calico.yaml"
  pull "$NODE"
  for i in busybox:1.37 nginx:1.29; do pull "$i"; done
  shop_images
}

load() { # IMAGE...: into every node of every cluster this lab made
  local c
  for c in $(kind get clusters 2>/dev/null); do
    for i in "$@"; do
      # Docker's containerd store keeps every platform's index, and `kind load
      # docker-image` then asks for layers it never pulled; saving one platform
      # first is what works.
      docker save --platform linux/amd64 "$i" -o /var/tmp/lab-image.tar
      kind load image-archive /var/tmp/lab-image.tar --name "$c" >/dev/null 2>&1
    done
  done
  rm -f /var/tmp/lab-image.tar
}

up() { # [CONFIG] [NAME]: a fresh cluster, the base images in it, kubectl pointed at it
  local config=${1:-$LAB/lab/cluster.yaml} name=${2:-shop}
  docker_up
  kind delete cluster --name "$name" >/dev/null 2>&1 || true
  mkdir -p /home/ana/.kube
  # No proxy reaches the nodes: they pull nothing (see the header).
  env -u HTTPS_PROXY -u https_proxy -u HTTP_PROXY -u http_proxy \
    kind create cluster --name "$name" --config "$config" --image "$NODE" -q
  for i in $BASE_IMAGES; do
    docker save --platform linux/amd64 "$i" -o /var/tmp/lab-image.tar
    kind load image-archive /var/tmp/lab-image.tar --name "$name" >/dev/null 2>&1
  done
  rm -f /var/tmp/lab-image.tar
  kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null
  kubectl -n kube-system rollout status deploy/coredns --timeout=180s >/dev/null
}

down() {
  local c
  for c in $(kind get clusters 2>/dev/null); do kind delete cluster --name "$c" >/dev/null 2>&1; done
}

case ${1:-} in
  tools) tools ;;
  up) shift; up "$@" ;;
  load) shift; load "$@" ;;
  down) down ;;
  *) echo "usage: lab.sh tools | up [CONFIG] [NAME] | load IMAGE... | down" >&2; exit 2 ;;
esac
