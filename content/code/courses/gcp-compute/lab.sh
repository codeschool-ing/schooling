#!/usr/bin/env bash
# The laptop every transcript in gcp-compute was recorded on, and what stands
# in for Google Cloud on it.
#
# THERE IS NO GOOGLE CLOUD ACCOUNT IN THIS COURSE, and nothing here is billed.
# Unlike AWS, Google Cloud has no open-source imitation of its control plane:
# nothing answers Compute Engine, Cloud Run, GKE, Cloud Functions, App Engine,
# Cloud Tasks, Cloud Scheduler or Artifact Registry on a laptop. So what runs is
# what can run without Google:
#   - gcloud 591.0.0, for what it does locally (configuration, help, Docker
#     credentials) and for the refusal every remote command meets with no
#     account;
#   - Terraform 1.17.1 with the google provider 8.9.0, for `validate` and
#     `plan`, which the provider computes on this machine. Every run is in a
#     network namespace with nothing but loopback unless LAB_HOSTS is set, so
#     a plan that printed was computed here and reached nobody;
#   - Docker, for the containers Cloud Run, Cloud Run jobs and App Engine
#     flexible run, built and started locally under the same contract;
#   - the Functions Framework, the Pub/Sub emulator from Google's emulators
#     image, and fake-gcs-server for Cloud Storage, for the event lessons;
#   - registry 3.1.2, the open-source OCI registry, for the protocol Artifact
#     Registry speaks.
# Everything else is taught from Google's documentation and marked as not run.
#
# THE STUDENT'S ENVIRONMENT IS BUILT FROM THE LESSON. `tools` reads the sh
# fences of lesson 1's section `your-lab` and runs them as they stand, with
# /home/ana as the home directory, so the setup the student follows is the one
# recorded.
#
# WHAT IS STAGED, and why.
#   - The first fence of `your-lab` (apt-get, needs sudo) is not run; `tools`
#     checks the commands it installs are present instead. This machine's
#     Docker is docker-ce 29.9.2 rather than Ubuntu's docker.io; the lessons
#     use nothing that differs between the two.
#   - The fifth fence (docker pull) is run against mirror.gcr.io, Google's
#     public cache of Docker Hub, for the three images that live on Docker Hub,
#     because this machine cannot reach Docker Hub itself; each is then tagged
#     with the name the lesson pulls. The emulators image comes from gcr.io as
#     the lesson says.
#   - The machine runs as root, with a directory of its own bind-mounted on
#     /home/ana. The prompt ana@laptop is printed by capture.sh, not by a shell.
#   - python3 is Ubuntu 24.04's own 3.12: this machine's default python3 is a
#     newer one, so PYTHON312 below goes first on the path.
#   - Every run gets its own network namespace with only loopback in it, so
#     nothing a capture does can reach Google. LAB_HOSTS=1 runs a capture on
#     the machine's own network instead, because a port Docker publishes is
#     not reachable from inside a namespace; those runs take a lock, so two of
#     them never share a container name. They reach nothing outside the laptop
#     either: the containers they start are local.
#   - Each run has a ~/gcp of its own (an empty directory with the virtual
#     environment bound into it), a ~/.config/gcloud and a ~/.docker of its
#     own, so what one capture writes there is gone when it ends and no other
#     capture sees it.
#
#   bash lab.sh tools                    # once: the student's environment
#   bash lab.sh run CMD...               # CMD in a fresh lab, as ana, in ~/gcp
#   LAB_HOSTS=1 bash lab.sh run CMD...   # the same, on the machine's network
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=/var/tmp/gcp-compute
HOMEDIR=$ROOT/home
PYTHON312=$ROOT/python312
LOCK=$ROOT/hosts.lock
LESSON1=$COURSE/lessons/le-0wj8wcjn
EMULATORS=gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators
HUB_IMAGES="fsouza/fake-gcs-server:1.56.1 registry:3.1.2 python:3.12.13-slim"

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

daemon() {
  if ! docker info >/dev/null 2>&1; then
    setsid dockerd >/var/log/gcp-compute-dockerd.log 2>&1 </dev/null &
    for _ in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 0.5; done
  fi
  docker info >/dev/null 2>&1
}

tools() {
  for c in python3.12 curl unzip jq docker ip; do
    command -v "$c" >/dev/null || { echo "install first: $c"; exit 1; }
  done
  mkdir -p "$ROOT" "$HOMEDIR" "$PYTHON312" /home/ana
  ln -sf /usr/bin/python3.12 "$PYTHON312/python3"
  # the fences run with /home/ana as home, so the paths they write are the
  # student's
  unshare --mount --propagation private -- bash -c '
    set -e
    mount --bind "$1" /home/ana
    export HOME=/home/ana PATH="$2:/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin" CHECKPOINT_DISABLE=1
    cd /home/ana
    if [ ! -x /home/ana/.local/bin/terraform ]; then bash -e <(bash "$3" fence "$4/your-lab.md" 2); fi
    if [ ! -x /home/ana/gcp/venv/bin/functions-framework ]; then bash -e <(bash "$3" fence "$4/your-lab.md" 3); fi
    if [ ! -f /home/ana/.terraformrc ]; then bash -e <(bash "$3" fence "$4/your-lab.md" 4); fi
  ' tools "$HOMEDIR" "$PYTHON312" "$COURSE/lab.sh" "$LESSON1"
  daemon
  docker image inspect "$EMULATORS" >/dev/null 2>&1 || docker pull -q "$EMULATORS" >/dev/null
  for i in $HUB_IMAGES; do
    case $i in */*) m=$i ;; *) m=library/$i ;; esac
    docker image inspect "$i" >/dev/null 2>&1 || {
      docker pull -q "mirror.gcr.io/$m" >/dev/null
      docker tag "mirror.gcr.io/$m" "$i"
    }
  done
}

run() {
  [ -x "$HOMEDIR/gcp/venv/bin/functions-framework" ] || { echo "run 'bash lab.sh tools' first"; exit 1; }
  if [ -n "${LAB_HOSTS:-}" ]; then
    # no network namespace: a port Docker publishes is on the machine's own
    # network. The lock makes these runs one at a time.
    exec flock "$LOCK" unshare --mount --propagation private -- bash "$COURSE/lab.sh" inside "$@"
  fi
  exec unshare --net --mount --propagation private -- bash "$COURSE/lab.sh" inside "$@"
}

inside() {
  [ -n "${LAB_HOSTS:-}" ] || ip link set lo up
  mount --bind "$HOMEDIR" /home/ana
  local work; work=$(mktemp -d "$ROOT/run.XXXXXX")
  # Every run gets a ~/gcp of its own: an empty directory with the virtual
  # environment bound back into it; and its own gcloud and Docker settings.
  mkdir -p "$work/gcp/venv" "$work/gcloud" "$work/docker" "$HOMEDIR/.config/gcloud" "$HOMEDIR/.docker"
  mount --bind "$work/gcp" /home/ana/gcp
  mount --bind "$HOMEDIR/gcp/venv" /home/ana/gcp/venv
  mount --bind "$work/gcloud" /home/ana/.config/gcloud
  mount --bind "$work/docker" /home/ana/.docker
  cat > "$work/env" <<ENV
export HOME=/home/ana USER=ana LOGNAME=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
export PATH=$PYTHON312:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
ENV
  # then the lines the student types in every new terminal, out of the lesson
  sh_fence "$LESSON1/your-lab.md" 6 >> "$work/env"
  local status=0
  env -i bash -c 'cd /home/ana; . "$1"; shift; "$@"' lab "$work/env" "$@" || status=$?
  umount -l /home/ana/.docker /home/ana/.config/gcloud /home/ana/gcp/venv /home/ana/gcp 2>/dev/null || true
  # never delete through a mount still in place: the venv is shared by every run
  if mountpoint -q "$work/gcp/venv" || [ -n "$(ls -A "$work/gcp/venv" 2>/dev/null)" ]; then
    echo "lab.sh: $work/gcp/venv is still mounted; leaving $work in place" >&2
  else
    rm -r -- "${work:?}"
  fi
  return $status
}

case ${1:-} in
  tools) tools ;;
  run) shift; run "$@" ;;
  inside) shift; inside "$@" ;;
  fence) shift; sh_fence "$@" ;;
  *) echo "usage: lab.sh tools | run CMD..." >&2; exit 2 ;;
esac
