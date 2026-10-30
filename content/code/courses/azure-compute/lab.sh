#!/usr/bin/env bash
# The laptop every transcript in azure-compute was recorded on, and the parts
# of Azure that can run on it.
#
# THERE IS NO AZURE ACCOUNT IN THIS COURSE, and nothing here is billed. Unlike
# AWS, no emulator answers Azure's control plane: nothing on a laptop creates
# a subscription, a virtual machine, a scale set, an AKS cluster, a Container
# App, an App Service plan or a Logic App. What runs here is what Microsoft
# ships to run locally, and the course says each time which one answered:
#   - the Azure CLI 2.91.0 and the Bicep compiler 0.48.1, which check a
#     declaration against Azure's own resource types without a subscription;
#   - Docker, running the same images Azure would run;
#   - Azurite 3.37.0, the Azure Storage emulator;
#   - the Functions host, in Microsoft's own image
#     mcr.microsoft.com/azure-functions/python:4-python3.12;
#   - kind, a Kubernetes cluster in Docker containers, for the AKS lessons;
#   - the Service Bus and Event Hubs emulators.
#
# THE STUDENT'S ENVIRONMENT IS BUILT FROM THE LESSON. `tools` reads the sh
# fences of lesson 1's section `your-lab` and runs them as they stand, with
# /home/ana as the home directory, so the setup the student follows is the one
# recorded. Every run then starts with the lines of that section's third
# fence, the ones a student types in every new terminal.
#
# WHAT IS STAGED, and why.
#   - The first fence of `your-lab` (apt-get, needs sudo) is not run; `tools`
#     checks its packages are installed instead.
#   - The machine runs as root, with /home/ana as ana's home. The prompt
#     ana@laptop is printed by capture.sh, not by a shell.
#   - python3 is Ubuntu 24.04's own 3.12: this machine's default python3 is a
#     newer one, so PYTHON312 below goes first on the path.
#   - This machine reaches the internet through a proxy that re-signs TLS. A
#     container cannot verify that signature, so `tools` rebuilds the two base
#     images the lessons build on (python:3.12-slim and the Functions image)
#     with the proxy's certificate added to their trust store and pip pointed
#     at it, and tags them with their own names. Nothing else in them differs,
#     and the student's copies need none of it.
#   - Images from Docker Hub come through mirror.gcr.io, Google's public cache
#     of Docker Hub, set as the daemon's registry mirror.
#   - kind 0.33.0 was built from its source with `go install` rather than
#     downloaded, because this machine may not run a binary it downloaded. It
#     is the same release the student downloads, and reports the same version.
#   - kubectl is the one inside kind's node image (`lab_kubectl` below), run
#     through `docker exec` against the cluster's own admin configuration:
#     the student's is the kubectl the `kubernetes` course installed. A file
#     given with -f is passed on standard input, unchanged.
#   - Every run takes a lock, so two captures never share Docker's ports or
#     container names, and has a ~/azure of its own (an empty directory with
#     the virtual environment bound into it), so what one capture writes there
#     is gone when it ends and no other capture sees it.
#
#   bash lab.sh tools            # once: the student's environment, the images
#   bash lab.sh run CMD...       # CMD in a fresh lab, as ana, in ~/azure
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=/var/tmp/azure-compute
HOMEDIR=/home/ana
PYTHON312=$ROOT/python312
LABBIN=$ROOT/bin
LOCK=$ROOT/lab.lock
LESSON1=$COURSE/lessons/le-7tsvt6an
IMAGES=(
  mcr.microsoft.com/azure-storage/azurite:3.37.0
  mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1
  mcr.microsoft.com/azure-messaging/eventhubs-emulator:2.2.1
  mcr.microsoft.com/mssql/server:2022-latest
  registry:3
  redis:8-alpine
  daprio/daprd:1.17.16
  kindest/node:v1.37.0
)
# the bases a lesson builds FROM, which get the proxy's certificate
BASES=(
  python:3.12-slim
  mcr.microsoft.com/azure-functions/python:4-python3.12
)

# sh_fence FILE N: the Nth ```sh fence of FILE, counted from 1
sh_fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
}

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

daemon() {
  mkdir -p /etc/docker
  printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
  if ! docker info >/dev/null 2>&1; then
    setsid dockerd >/var/log/azure-compute-dockerd.log 2>&1 </dev/null &
    for _ in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 0.5; done
  fi
  docker info >/dev/null 2>&1
}

# a base image with the proxy's certificate in it, under its own name
with_proxy_ca() {
  local base=$1 orig dir
  orig=lab-orig/$(printf '%s' "$base" | tr '/:' '__')
  docker image inspect "$orig" >/dev/null 2>&1 && return 0
  docker image inspect "$base" >/dev/null 2>&1 || docker pull -q "$base" >/dev/null
  docker tag "$base" "$orig"
  dir=$(mktemp -d)
  cp /root/.ccr/ca-bundle.crt "$dir/proxy-ca.crt"
  cat > "$dir/Dockerfile" <<EOF
FROM $orig
COPY proxy-ca.crt /usr/local/share/ca-certificates/lab-proxy.crt
RUN cat /usr/local/share/ca-certificates/lab-proxy.crt >> /etc/ssl/certs/ca-certificates.crt
ENV PIP_CERT=/etc/ssl/certs/ca-certificates.crt REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
EOF
  docker build -q -t "$base" "$dir" >/dev/null
  rm -rf "$dir"
}

tools() {
  for p in python3.12 python3.12-venv curl unzip jq; do
    installed "$p" || { echo "install first: $p"; exit 1; }
  done
  mkdir -p "$ROOT" "$HOMEDIR" "$PYTHON312" "$LABBIN"
  ln -sf /usr/bin/python3.12 "$PYTHON312/python3"
  if [ ! -x "$ROOT/venv/bin/az" ] || [ ! -x "$HOMEDIR/.azure/bin/bicep" ]; then
    env -i HOME="$HOMEDIR" PATH="$PYTHON312:$HOMEDIR/.local/bin:/usr/local/bin:/usr/bin:/bin" \
      HTTPS_PROXY="${HTTPS_PROXY:-}" PIP_CERT="${PIP_CERT:-}" REQUESTS_CA_BUNDLE=/root/.ccr/ca-bundle.crt \
      bash -ec 'cd "$HOME"; eval "$(bash "$1" fence "$2/your-lab.md" 2)"' tools "$COURSE/lab.sh" "$LESSON1"
    # the virtual environment keeps its path, ~/azure/venv, because every run
    # binds it back there; it is kept outside so a run's empty ~/azure can sit
    # on top of /home/ana/azure
    rm -rf "$ROOT/venv" && mv "$HOMEDIR/azure/venv" "$ROOT/venv"
  fi
  daemon
  for i in "${IMAGES[@]}"; do
    docker image inspect "$i" >/dev/null 2>&1 || docker pull -q "$i" >/dev/null
  done
  for b in "${BASES[@]}"; do with_proxy_ca "$b"; done
  if [ ! -x "$HOMEDIR/.local/bin/kind" ]; then
    GOTOOLCHAIN=local GOBIN="$HOMEDIR/.local/bin" go install sigs.k8s.io/kind@v0.33.0
  fi
  cat > "$LABBIN/kubectl" <<'EOF'
#!/usr/bin/env bash
# kubectl, run inside the control-plane node of the cluster named by
# LAB_KIND (default shop). A file named with -f goes in on standard input.
node="${LAB_KIND:-shop}-control-plane"
args=() input=
while [ $# -gt 0 ]; do
  case $1 in
    -f|--filename) if [ "$2" != - ]; then input=$2; args+=(-f -); else args+=(-f -); fi; shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
if [ -n "$input" ]; then
  exec docker exec -i "$node" kubectl --kubeconfig /etc/kubernetes/admin.conf "${args[@]}" < "$input"
fi
exec docker exec -i "$node" kubectl --kubeconfig /etc/kubernetes/admin.conf "${args[@]}"
EOF
  chmod +x "$LABBIN/kubectl"
}

run() {
  [ -x "$ROOT/venv/bin/az" ] || { echo "run 'bash lab.sh tools' first"; exit 1; }
  exec flock "$LOCK" bash "$COURSE/lab.sh" inside "$@"
}

inside() {
  work=$(mktemp -d "$ROOT/run.XXXXXX")
  mkdir -p "$work/azure/venv"
  mkdir -p "$HOMEDIR/azure"
  mount --bind "$work/azure" "$HOMEDIR/azure"
  mount --bind "$ROOT/venv" "$HOMEDIR/azure/venv"
  cat > "$work/env" <<EOF
export HOME=$HOMEDIR USER=ana LOGNAME=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
export PATH=$PYTHON312:$LABBIN:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
EOF
  # then the lines the student types in every new terminal, out of the lesson
  sh_fence "$LESSON1/your-lab.md" 3 >> "$work/env"
  local status=0
  # never remove the run's directory while the environment is still bound
  # inside it: that would delete the environment itself
  trap 'umount "$HOMEDIR/azure/venv" && umount "$HOMEDIR/azure" && rm -rf "$work"' EXIT
  env -i bash -c 'cd "$HOME"; . "$1"; shift; "$@"' lab "$work/env" "$@" || status=$?
  return $status
}

case ${1:-} in
  tools) tools ;;
  run) shift; run "$@" ;;
  inside) shift; inside "$@" ;;
  fence) shift; sh_fence "$@" ;;
  *) echo "usage: lab.sh tools | run CMD..." >&2; exit 2 ;;
esac
