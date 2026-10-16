#!/usr/bin/env bash
# The laptop every transcript in aws-compute was recorded on, and the AWS it
# talks to.
#
# THERE IS NO AWS ACCOUNT IN THIS COURSE, and nothing here is billed. The AWS
# the command line talks to is moto 5.2.3, the open-source imitation of the AWS
# API that aws-foundations, aws-operations and aws-data also use: a Python
# program answering the AWS APIs on 127.0.0.1:4567, keeping what it was told in
# memory and forgetting it when it stops. It runs no machine and no container.
# An instance it "launches" is a record with an id and a state.
#
# THE STUDENT'S ENVIRONMENT IS BUILT FROM THE LESSON. `tools` reads the sh
# fences of lesson 1's section `your-lab` and runs them as they stand, with
# /home/ana as the home directory, so the setup the student follows is the one
# recorded. prices.py is read out of the example in lesson 1's section
# `the-price-sheet` (capture.sh, from_example).
#
# WHAT IS STAGED, and why.
#   - The first fence of `your-lab` (apt-get, needs sudo) is not run; `tools`
#     checks its packages are installed instead.
#   - The machine runs as root, with a directory of its own bind-mounted on
#     /home/ana. The prompt ana@laptop is printed by capture.sh, not by a shell.
#   - python3 is Ubuntu 24.04's own 3.12: this machine's default python3 is a
#     newer one, so PYTHON312 below goes first on the path.
#   - Every run gets its own network namespace, so moto is always on
#     127.0.0.1:4567 and always EMPTY when a capture starts. The student starts
#     moto_server in a terminal of their own; here the lab starts it before the
#     first command, from the same virtual environment, with the same flags.
#   - Docker (lessons 9, 10, 14 and 17): this machine cannot reach Docker Hub,
#     ghcr.io or public.ecr.aws for image layers, so `tools` pulls the two images
#     those lessons use through mirror.gcr.io, Google's public cache of Docker
#     Hub, and tags them with the names the lessons use. Lambda's base image is
#     the same image AWS publishes both as public.ecr.aws/lambda/python:3.12
#     and as amazon/aws-lambda-python:3.12 on Docker Hub. LAB_HOSTS=1 runs such
#     a capture on the machine's own network, because a port published by
#     Docker is not reachable from inside a network namespace; those runs take
#     a lock, so two of them never share moto.
#
#   bash lab.sh tools            # once: the student's environment, the images
#   bash lab.sh run CMD...       # CMD in a fresh lab, as ana, in ~/aws
#   LAB_MOTO_ENV='INITIAL_NO_AUTH_ACTION_COUNT=0' bash lab.sh run CMD...
#                                # moto started with that environment
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=/var/tmp/aws-compute
HOMEDIR=$ROOT/home
PYTHON312=$ROOT/python312
LOCK=$ROOT/hosts.lock
LESSON1=$COURSE/lessons/le-ps61q5st
LAMBDA_IMAGE=public.ecr.aws/lambda/python:3.12
WEB_IMAGE=nginx:1.29-alpine

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
    setsid dockerd >/var/log/aws-compute-dockerd.log 2>&1 </dev/null &
    for _ in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 0.5; done
  fi
  docker info >/dev/null 2>&1
}

tools() {
  for p in python3.12 python3.12-venv curl unzip jq iproute2; do
    installed "$p" || { echo "install first: $p"; exit 1; }
  done
  mkdir -p "$ROOT" "$HOMEDIR" "$PYTHON312"
  ln -sf /usr/bin/python3.12 "$PYTHON312/python3"
  # the fences run with /home/ana as home, so the paths the installer writes
  # are the student's
  unshare --mount --propagation private -- bash -c '
    set -e
    mount --bind "$1" /home/ana
    export HOME=/home/ana PATH="$2:/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin"
    cd /home/ana
    if [ ! -x /home/ana/.local/bin/aws ]; then bash -e <(bash "$3" fence "$4/your-lab.md" 2); fi
    if [ ! -x /home/ana/aws/venv/bin/moto_server ]; then bash -e <(bash "$3" fence "$4/your-lab.md" 3); fi
  ' tools "$HOMEDIR" "$PYTHON312" "$COURSE/lab.sh" "$LESSON1"
  daemon
  docker image inspect "$LAMBDA_IMAGE" >/dev/null 2>&1 || {
    docker pull -q mirror.gcr.io/amazon/aws-lambda-python:3.12 >/dev/null
    docker tag mirror.gcr.io/amazon/aws-lambda-python:3.12 "$LAMBDA_IMAGE"
  }
  docker image inspect "$WEB_IMAGE" >/dev/null 2>&1 || {
    docker pull -q "mirror.gcr.io/library/$WEB_IMAGE" >/dev/null
    docker tag "mirror.gcr.io/library/$WEB_IMAGE" "$WEB_IMAGE"
  }
}

run() {
  [ -x "$HOMEDIR/aws/venv/bin/moto_server" ] || { echo "run 'bash lab.sh tools' first"; exit 1; }
  if [ -n "${LAB_HOSTS:-}" ]; then
    exec flock "$LOCK" unshare --mount --propagation private -- bash "$COURSE/lab.sh" inside "$@"
  fi
  exec unshare --net --mount --propagation private -- bash "$COURSE/lab.sh" inside "$@"
}

inside() {
  [ -n "${LAB_HOSTS:-}" ] || ip link set lo up
  mount --bind "$HOMEDIR" /home/ana
  local work; work=$(mktemp -d "$ROOT/run.XXXXXX")
  # ~/aws holds the virtual environment and stays; what a run writes beside it
  # is removed afterwards, so every capture starts from the same directory
  local before; before=$(ls -A /home/ana/aws)
  env ${LAB_MOTO_ENV:-} /home/ana/aws/venv/bin/moto_server -p 4567 >"$work/moto.log" 2>&1 </dev/null &
  local moto=$!
  for _ in $(seq 80); do curl -s -o /dev/null http://127.0.0.1:4567/ && break; sleep 0.25; done
  cat > "$work/env" <<EOF
export HOME=/home/ana USER=ana LOGNAME=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
export PATH=$PYTHON312:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export LAB_MOTO_PID=$moto
EOF
  # then the lines the student types in every new terminal, out of the lesson
  sh_fence "$LESSON1/your-lab.md" 4 >> "$work/env"
  local status=0
  env -i bash -c 'cd /home/ana; . "$1"; shift; "$@"' lab "$work/env" "$@" || status=$?
  kill "$moto" 2>/dev/null || true
  wait "$moto" 2>/dev/null || true
  local f
  for f in $(ls -A /home/ana/aws); do
    grep -qxF "$f" <<<"$before" || rm -rf "/home/ana/aws/$f"
  done
  rm -rf "$work"
  return $status
}

case ${1:-} in
  tools) tools ;;
  run) shift; run "$@" ;;
  inside) shift; inside "$@" ;;
  fence) shift; sh_fence "$@" ;;
  *) echo "usage: lab.sh tools | run CMD..." >&2; exit 2 ;;
esac
