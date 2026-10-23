#!/usr/bin/env bash
# The laptop every transcript in secure-pipeline was recorded on: one Linux
# machine with a real Docker Engine, the student `ana`, her project ~/linkbox,
# the CI she builds for it in lesson 1, and the scanners the later lessons
# install one at a time.
#
#   sudo bash lab.sh tools          # once: the user, the daemon, every program
#                                   # and image a lesson uses
#   sudo bash lab.sh project N      # ~/linkbox and its CI as they stand at the
#                                   # START of lesson N, with a fixed history
#   sudo bash lab.sh check          # every file a lesson shows whole, against
#                                   # the stage it belongs to (lab/stages)
#   sudo bash lab.sh as CMD...      # CMD as ana, with ana's environment
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Every file of the project is shown
# whole in the lesson that writes or changes it, under a line ending in
# "as `PATH`:". lab/stages/NN holds the same files as they stand at the end of
# lesson NN; `project` builds the repository from those, and `check` compares
# them with what the lessons show, byte for byte, so the two cannot drift.
#
# WHAT IS STAGED, and why.
#   - The machine reaches the internet through a proxy that re-signs TLS with a
#     certificate authority of its own. The host trusts it; a container does
#     not. Two things follow. Docker Hub is reached through Google's mirror,
#     mirror.gcr.io, one line of /etc/docker/daemon.json (the names, tags and
#     digests are Docker Hub's). And `pip install` inside `docker build` could
#     not reach PyPI, so the two Python base images the lessons build FROM are
#     re-tagged locally with two files added: the proxy's CA in the system
#     store, and an /etc/pip.conf naming the proxy. Nothing else in them
#     changes, and no package is added, so a scanner reads the same packages
#     as in the image Docker Hub serves. A small TCP relay on the Docker
#     bridge carries the builds' traffic to the proxy.
#   - Trivy's vulnerability database is downloaded once, on the day of the
#     recording, and every later capture runs with TRIVY_SKIP_DB_UPDATE=true,
#     so every count in the course comes from the same database. Lesson 8
#     shows the download itself. On a student's machine the database is a day
#     old at most and every count differs; the lessons say so.
#   - Semgrep runs with SEMGREP_ENABLE_VERSION_CHECK=0: the machine cannot
#     reach semgrep.dev, and the check costs a minute and a half of waiting
#     before it gives up. The lessons use only rules written in them.
#   - uv is the released binary, copied into ~/.local/bin rather than fetched
#     by the install script from astral.sh, which this machine cannot reach.
#     Every other program is the release the lessons download, from the same
#     URL, checked against the published checksum.
#   - The history is staged, not lived: every commit carries a fixed date, so
#     a lesson that prints a hash prints the same one every time.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.9, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ANA=/home/ana
BIN=$ANA/.local/bin
CACHE=/var/cache/secure-pipeline

UV=0.11.32
TRIVY=0.75.0
GITLEAKS=8.30.1
SYFT=1.54.1
COSIGN=3.1.3
CONFTEST=0.71.0
KIND=0.33.0
KUBECTL=v1.37.1
VAULT=2.1.2
NODE=kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
# Python tools, installed with `uv tool install` at these versions.
PYTOOLS="bandit==1.9.4 semgrep==1.182.1 pip-audit==2.10.1 zizmor==1.31.1"
# The images the lessons pull, by the tag they name.
IMAGES="python:3.13 python:3.13-slim gcr.io/distroless/python3-debian13:nonroot
zaproxy/zap-stable:2.17.0 registry:3.1.2 hashicorp/vault:2.1.2 $NODE"

as_ana() { # CMD...: as ana, in ana's home, with the environment every capture has
  runuser -u ana -- env -i HOME=$ANA USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=$BIN:/usr/local/bin:/usr/bin:/bin TZ=$TZ LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=dumb \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${HTTPS_PROXY:-}" \
    NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    TRIVY_SKIP_DB_UPDATE=${TRIVY_SKIP_DB_UPDATE:-true} \
    TRIVY_SKIP_JAVA_DB_UPDATE=true SEMGREP_ENABLE_VERSION_CHECK=0 \
    bash -c 'cd ~ && "$@"' bash "$@"
}

docker_up() {
  docker info >/dev/null 2>&1 && return 0
  mkdir -p /etc/docker
  [ -f /etc/docker/daemon.json ] || echo '{"registry-mirrors":["https://mirror.gcr.io"]}' >/etc/docker/daemon.json
  setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
  for _ in $(seq 60); do docker info >/dev/null 2>&1 && return 0; sleep 1; done
  echo "dockerd did not start; see /var/log/dockerd.log" >&2; return 1
}

relay_up() { # the builds' road to the proxy: 172.17.0.1:3128 -> the proxy
  local gw port
  gw=$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}')
  port=${HTTPS_PROXY##*:}
  python3 - "$gw" 2>/dev/null <<'PY' && return 0
import socket, sys
s = socket.socket(); s.settimeout(1)
sys.exit(0 if s.connect_ex((sys.argv[1], 3128)) == 0 else 1)
PY
  setsid python3 "$LAB/lab/relay.py" "$gw" 3128 127.0.0.1 "$port" >/var/log/lab-relay.log 2>&1 </dev/null &
  sleep 1
}

pull() { # IMAGE, retried: the mirror answers 429 under load
  docker image inspect "$1" >/dev/null 2>&1 && return 0
  for i in 1 2 3 4 5; do docker pull -q "$1" >/dev/null && return 0; sleep $((i * 10)); done
  echo "could not pull $1" >&2; return 1
}

base_images() { # python:3.13 and python:3.13-slim, able to reach PyPI through the relay
  local gw tag dir
  gw=$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}')
  for tag in python:3.13 python:3.13-slim; do
    docker image inspect "$tag" --format '{{index .Config.Labels "lab.staged"}}' 2>/dev/null | grep -q yes && continue
    pull "$tag"
    dir=$(mktemp -d)
    cp /usr/local/share/ca-certificates/lab-proxy.crt "$dir/"
    printf '[global]\nproxy = http://%s:3128\ncert = /etc/ssl/certs/ca-certificates.crt\n' "$gw" >"$dir/pip.conf"
    printf 'FROM %s\nCOPY lab-proxy.crt /usr/local/share/ca-certificates/\nCOPY pip.conf /etc/pip.conf\nRUN update-ca-certificates >/dev/null\nLABEL lab.staged=yes\n' "$tag" >"$dir/Dockerfile"
    docker build -q -t "$tag" "$dir" >/dev/null
    rm -rf "$dir"
  done
}

release() { # NAME URL SUMS-URL [MEMBER]: a released binary into ~/.local/bin, checked
  local name=$1 url=$2 sums=$3 member=${4:-$1} dir file
  [ -x "$BIN/$name" ] && return 0
  dir=$(mktemp -d) && file=${url##*/}
  curl -sSfLo "$dir/$file" "$url"
  (cd "$dir" && curl -sSfL "$sums" | grep " \*\?$file\$" | sha256sum -c --quiet)
  case $file in
    *.tar.gz) tar -xzf "$dir/$file" -C "$dir" "$member" && install -m 755 -o ana -g ana "$dir/$member" "$BIN/$name" ;;
    *.zip) (cd "$dir" && python3 -m zipfile -e "$file" .) && install -m 755 -o ana -g ana "$dir/$member" "$BIN/$name" ;;
    *) install -m 755 -o ana -g ana "$dir/$file" "$BIN/$name" ;;
  esac
  rm -rf "$dir"
}

tools() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  docker_up
  usermod -aG docker ana
  install -d -o ana -g ana "$ANA/.local" "$BIN" "$ANA/.cache"
  cp /root/.ccr/agent-proxy-ca.crt /usr/local/share/ca-certificates/lab-proxy.crt 2>/dev/null || true
  relay_up
  base_images
  for i in $IMAGES; do pull "$i"; done
  [ -x "$BIN/uv" ] || install -m 755 -o ana -g ana "$(command -v uv)" "$BIN/uv"
  local gh=https://github.com
  release trivy "$gh/aquasecurity/trivy/releases/download/v$TRIVY/trivy_${TRIVY}_Linux-64bit.tar.gz" \
    "$gh/aquasecurity/trivy/releases/download/v$TRIVY/trivy_${TRIVY}_checksums.txt"
  release gitleaks "$gh/gitleaks/gitleaks/releases/download/v$GITLEAKS/gitleaks_${GITLEAKS}_linux_x64.tar.gz" \
    "$gh/gitleaks/gitleaks/releases/download/v$GITLEAKS/gitleaks_${GITLEAKS}_checksums.txt"
  release syft "$gh/anchore/syft/releases/download/v$SYFT/syft_${SYFT}_linux_amd64.tar.gz" \
    "$gh/anchore/syft/releases/download/v$SYFT/syft_${SYFT}_checksums.txt"
  release conftest "$gh/open-policy-agent/conftest/releases/download/v$CONFTEST/conftest_${CONFTEST}_Linux_x86_64.tar.gz" \
    "$gh/open-policy-agent/conftest/releases/download/v$CONFTEST/checksums.txt"
  release cosign "$gh/sigstore/cosign/releases/download/v$COSIGN/cosign-linux-amd64" \
    "$gh/sigstore/cosign/releases/download/v$COSIGN/cosign_checksums.txt"
  release kind "$gh/kubernetes-sigs/kind/releases/download/v$KIND/kind-linux-amd64" \
    "$gh/kubernetes-sigs/kind/releases/download/v$KIND/kind-linux-amd64.sha256sum"
  if [ ! -x "$BIN/kubectl" ]; then
    curl -sSfLo /var/tmp/kubectl "https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl"
    echo "$(curl -sSfL "https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl.sha256")  /var/tmp/kubectl" | sha256sum -c --quiet
    install -m 755 -o ana -g ana /var/tmp/kubectl "$BIN/kubectl" && rm /var/tmp/kubectl
  fi
  local t
  for t in $PYTOOLS; do
    as_ana sh -c "command -v ${t%%==*} >/dev/null || uv tool install -q '$t'"
  done
  # Trivy's database, once, so every capture reads the same one.
  [ -d "$ANA/.cache/trivy/db" ] || TRIVY_SKIP_DB_UPDATE=false as_ana trivy image --download-db-only -q
}

# ---- the project, as it stands at the start of lesson N
# The date each lesson's commit carries: one working day per lesson, from
# Monday 5 October 2026, in São Paulo.
commit_date() { python3 -c "
import datetime as d, sys
n = int(sys.argv[1]); day = d.date(2026, 10, 5)
while n > 1:
    day += d.timedelta(days=1)
    if day.weekday() < 5: n -= 1
print(day.isoformat() + 'T10:00:00-03:00')" "$1"; }

project() { # N: ~/linkbox with the files of lessons 1..N-1, one commit each,
  # and the CI of lesson 1 with no runs yet
  local n=$1 i st msg
  as_ana rm -rf linkbox ci
  # lesson 1 has the student set their own name; this is ana's
  as_ana git config --global user.name 'Ana Lima'
  as_ana git config --global user.email ana@example.org
  as_ana git config --global init.defaultBranch main
  as_ana mkdir linkbox
  as_ana git -C linkbox init -q -b main
  for ((i = 1; i < n; i++)); do
    st=$(printf '%s/lab/stages/%02d' "$LAB" "$i")
    [ -d "$st" ] || continue
    msg=$(cat "$st.msg" 2>/dev/null || echo "lesson $i")
    (cd "$st" && tar -cf - --exclude=./.deleted --exclude=./_home .) | as_ana tar -xf - -C linkbox
    if [ -d "$st/_home" ]; then (cd "$st/_home" && tar -cf - .) | as_ana tar -xf - -C "$ANA"; fi
    if [ -f "$st/.deleted" ]; then
      while read -r f; do as_ana rm -f "linkbox/$f"; done <"$st/.deleted"
    fi
    as_ana sh -c "cd linkbox && git add -A && GIT_AUTHOR_DATE=$(commit_date "$i") GIT_COMMITTER_DATE=$(commit_date "$i") \
      git commit -q -m '$msg'"
  done
  if [ "$n" -gt 8 ]; then # the registry lesson 8 starts, empty
    docker rm -f registry >/dev/null 2>&1 || true
    as_ana docker run -d --restart=always -p 127.0.0.1:5000:5000 --name registry registry:3.1.2 >/dev/null
  fi
  if [ "$n" -gt 14 ]; then # the signing key lesson 14 makes for the CI server
    as_ana sh -c 'mkdir -p ~/ci/keys && cd ~/ci/keys && rm -f cosign.* password offline.json &&
      openssl rand -base64 24 >password && chmod 600 password &&
      COSIGN_PASSWORD=$(cat password) cosign generate-key-pair >/dev/null 2>&1 &&
      cosign signing-config create --out offline.json >/dev/null 2>&1'
  fi
  if [ "$n" -gt 1 ]; then # the CI server lesson 1 builds
    as_ana mkdir -p ci
    as_ana git init -q --bare -b main ci/linkbox.git
    shown "$LAB/lessons/le-4588gzk1/the-pipeline.md" "~/ci/linkbox.git/hooks/post-receive" | as_ana tee ci/linkbox.git/hooks/post-receive >/dev/null
    as_ana chmod +x ci/linkbox.git/hooks/post-receive
    as_ana sh -c 'cd linkbox && git remote add ci ~/ci/linkbox.git && git push -q ci main >/dev/null 2>&1'
    as_ana rm -rf ci/runs
  fi
}

# ---- what a lesson shows, against what the stages hold
shown() { # MD NAME: the fence under the paragraph ending in "as `NAME`:"
  python3 "$LAB/lab/shown.py" "$1" "$2"
}

check() { python3 "$LAB/lab/shown.py" --check "$LAB"; }

case ${1:-} in
  tools) tools ;;
  project) project "$2" ;;
  check) check ;;
  as) shift; as_ana "$@" ;;
  shown) shown "$2" "$3" ;;
  date) commit_date "$2" ;;
  *) sed -n '2,20p' "$0"; exit 1 ;;
esac
