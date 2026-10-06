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
#   sudo bash lab.sh metrics        # metrics-server, for lessons 21, 33 and 34
#   sudo bash lab.sh calico         # Calico, on a cluster from lab/cluster-calico.yaml
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
# it (lesson 21 shows the requests). kind's default leaves the kubelets with
# self-signed certificates, and the usual workaround is a flag that turns the
# verification off. `lab.sh up` approves those requests as soon as they arrive,
# which a cluster's operator does by hand or with an approver they trust.
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
GATEWAY_API=v1.4.0   # the version Traefik v3.6 is built against
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
  # cloud-provider-kind's Envoy listens for its health check on "::", and
  # the recording machine's kernel has no IPv6, so Envoy refuses the address
  # and every LoadBalancer stays <pending>. One line is changed before the
  # build, to 0.0.0.0; on a machine with IPv6 the released binary works.
  if [ ! -x "$OPT/bin/cloud-provider-kind" ]; then
    dir=$(GOTOOLCHAIN=auto GOFLAGS=-mod=mod go mod download -json "sigs.k8s.io/cloud-provider-kind@$CLOUD_PROVIDER_KIND" | jq -r .Dir)
    rm -rf "$OPT/src/cloud-provider-kind" && cp -r "$dir" "$OPT/src/cloud-provider-kind" && chmod -R u+w "$OPT/src/cloud-provider-kind"
    sed -i '/^admin:/,/port_value: 10000/ s/address: "::"/address: "0.0.0.0"/' "$OPT/src/cloud-provider-kind/pkg/loadbalancer/proxy.go"
    (cd "$OPT/src/cloud-provider-kind" && GOTOOLCHAIN=auto GOFLAGS=-mod=mod CGO_ENABLED=0 go build -trimpath -o "$OPT/bin/cloud-provider-kind" .)
  fi
  wrap metrics-server "$METRICS_SERVER" "$OPT/bin/metrics-server"
  if [ ! -f "$OPT/manifests/metrics-server.yaml" ]; then
    dir=$(GOTOOLCHAIN=auto GOFLAGS=-mod=mod go mod download -json "sigs.k8s.io/metrics-server@$METRICS_SERVER" | jq -r .Dir)
    kubectl kustomize "$dir/manifests/base" |
      sed "s#image: gcr.io/k8s-staging-metrics-server/metrics-server:master#image: lab.local/metrics-server:$METRICS_SERVER#" \
      >"$OPT/manifests/metrics-server.yaml"
  fi
  [ -f "$OPT/manifests/calico.yaml" ] || curl -sSfo "$OPT/manifests/calico.yaml" \
    "https://raw.githubusercontent.com/projectcalico/calico/$CALICO/manifests/calico.yaml"
  if [ ! -d "$OPT/manifests/gateway-api-$GATEWAY_API" ]; then
    dir=$(GOTOOLCHAIN=auto go mod download -json "sigs.k8s.io/gateway-api@$GATEWAY_API" | jq -r .Dir)
    mkdir -p "$OPT/manifests/gateway-api-$GATEWAY_API"
    cp "$dir"/config/crd/standard/*.yaml "$OPT/manifests/gateway-api-$GATEWAY_API/"
  fi
  pull "$NODE"
  for i in busybox:1.37 nginx:1.29 traefik:v3.6 envoyproxy/envoy:v1.36.2 postgres:18 \
    calico/cni:$CALICO calico/node:$CALICO calico/kube-controllers:$CALICO; do pull "$i"; done
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
  env -u HTTPS_PROXY -u https_proxy -u HTTP_PROXY -u http_proxy -u NO_PROXY -u no_proxy \
    kind create cluster --name "$name" --config "$config" --image "$NODE" -q
  for i in $BASE_IMAGES; do
    docker save --platform linux/amd64 "$i" -o /var/tmp/lab-image.tar
    kind load image-archive /var/tmp/lab-image.tar --name "$name" >/dev/null 2>&1
  done
  rm -f /var/tmp/lab-image.tar
  # A cluster without kind's network plugin has no Ready node until one is
  # installed, so Calico goes in before anything waits for readiness.
  if grep -q 'disableDefaultCNI: true' "$config"; then calico; fi
  kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null
  serving_certs
  no_upstream_dns
  kubectl -n kube-system rollout status deploy/coredns --timeout=180s >/dev/null
}

no_upstream_dns() { # CoreDNS answers the cluster's own names and nothing else
  # A lab cluster has no business on the internet, and on the recording
  # machine a pod that asked for `shop` was once answered for `shop.`, the
  # real top-level domain, and sent its request out of the laptop. Taking
  # CoreDNS's `forward` block out leaves every name outside cluster.local
  # unanswered. A real cluster keeps it.
  kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' |
    sed '/^ *forward \. /,/^ *}/d' >/var/tmp/Corefile
  kubectl -n kube-system create configmap coredns --from-file=Corefile=/var/tmp/Corefile \
    --dry-run=client -o yaml | kubectl replace -f - >/dev/null
  rm -f /var/tmp/Corefile
  kubectl -n kube-system rollout restart deploy/coredns >/dev/null
}

serving_certs() { # approve each kubelet's request for a serving certificate
  # (see serverTLSBootstrap in the header). Without one, `kubectl logs` and
  # `kubectl exec` fail: the API server cannot verify the kubelet it dials.
  local want have
  want=$(kubectl get nodes --no-headers | wc -l)
  for _ in $(seq 60); do
    have=$(kubectl get csr --no-headers 2>/dev/null | grep -c 'kubelet-serving' || true)
    [ "$have" -ge "$want" ] && break
    sleep 2
  done
  kubectl get csr --no-headers | awk '/kubelet-serving/ && /Pending/ {print $1}' |
    xargs -r kubectl certificate approve >/dev/null
}

calico() { # Calico as the network plugin, on a cluster made from cluster-calico.yaml
  load "calico/cni:$CALICO" "calico/node:$CALICO" "calico/kube-controllers:$CALICO"
  kubectl apply -f "$OPT/manifests/calico.yaml" >/dev/null
  kubectl -n kube-system rollout status daemonset/calico-node --timeout=300s >/dev/null
  kubectl -n kube-system rollout status deployment/calico-kube-controllers --timeout=300s >/dev/null
  kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null
}

metrics() { # metrics-server, from its own manifests with the image built here
  load "lab.local/metrics-server:$METRICS_SERVER"
  kubectl apply -f "$OPT/manifests/metrics-server.yaml" >/dev/null
  kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s >/dev/null
}

down() {
  local c
  for c in $(kind get clusters 2>/dev/null); do kind delete cluster --name "$c" >/dev/null 2>&1; done
}

case ${1:-} in
  tools) tools ;;
  up) shift; up "$@" ;;
  load) shift; load "$@" ;;
  metrics) metrics ;;
  calico) calico ;;
  down) down ;;
  *) echo "usage: lab.sh tools | up [CONFIG] [NAME] | load IMAGE... | down" >&2; exit 2 ;;
esac
