#!/usr/bin/env bash
# The machine every transcript in the architecture course was recorded on.
#
# THE STUDENT NEVER RECEIVES THIS FILE. What they build is described in lesson 1,
# sections "Your lab" and "When the setup fails": an Ubuntu 24.04 virtual machine
# with Docker Engine and the Compose plugin from Docker's own repository, and a
# directory ~/lab with one sub-directory per exercise. Every program, Dockerfile
# and compose.yaml a lesson runs is shown whole in that lesson as a
# schooling-example; the captures EXTRACT them from the lesson's Markdown
# (lab/extract.py), so what ran is what the copy button hands over.
#
# IT IS ONE LINUX MACHINE WITH A REAL DOCKER ENGINE ON IT, called `vm`, with one
# user, ana, in the docker group. Nothing is emulated: the images are Docker
# Hub's, and every container was started by the command the lesson shows.
#
# WHAT IS STAGED, and why.
#   - Docker Hub images are pulled through mirror.gcr.io, Google's public cache of
#     Docker Hub ("registry-mirrors" in /etc/docker/daemon.json). The names, tags
#     and digests are Docker Hub's.
#   - The machine reaches the internet only through a proxy that re-signs TLS.
#     So the lab adds that proxy's CA certificate to its local copy of
#     python:3.12-slim (same tag), and every image a lesson builds is built once
#     beforehand with `docker build --network host` and the proxy in HTTPS_PROXY,
#     which BuildKit leaves out of the cache key. The `docker compose up --build`
#     a transcript shows then finds every layer in the cache. On the student's
#     machine the same Dockerfile downloads from PyPI directly.
#   - Every run starts from a clean daemon: no containers, volumes or networks
#     (images are kept, as on a machine where the lessons were done in order).
#   - Ids Docker invents, timings and timestamps are whatever that run produced.
#
#   sudo bash lab.sh tools          once: ana, the daemon, the staged base image
#   sudo bash lab.sh reset          remove every container, volume and network
#   sudo bash lab.sh prebuild DIR   build the images of the compose project in DIR
#   sudo bash lab.sh as 'cmd'       run a command as ana, in a login shell
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

daemon() {
  mkdir -p /etc/docker
  printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
  if ! docker info >/dev/null 2>&1; then
    setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
    for _ in $(seq 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
  fi
  docker info >/dev/null 2>&1
}

tools() {
  id ana >/dev/null 2>&1 || useradd --create-home --shell /bin/bash ana
  getent group docker >/dev/null || groupadd docker
  usermod -aG docker ana
  echo 'ana ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ana
  daemon
  chgrp docker /var/run/docker.sock
  # the staged base image: python:3.12-slim plus the proxy's CA
  local t; t=$(mktemp -d)
  docker pull -q python:3.12-slim >/dev/null
  cp /root/.ccr/ca-bundle.crt "$t/ca.crt"
  printf 'FROM python:3.12-slim\nCOPY ca.crt /usr/local/share/ca-certificates/proxy.crt\nRUN update-ca-certificates\n' > "$t/Dockerfile"
  docker build -q -t python:3.12-slim "$t" >/dev/null
  rm -rf "$t"
}

reset() {
  local ids
  ids=$(docker ps -aq); [ -n "$ids" ] && docker rm -f $ids >/dev/null
  docker volume prune -af >/dev/null
  docker network prune -f >/dev/null
  rm -rf /home/ana/lab
}

prebuild() { # every service with a build context, under the name compose gives it
  local dir=$1 project
  project=$(basename "$dir")
  ( cd "$dir" && docker compose config --format json ) | python3 -c '
import json, sys
c = json.load(sys.stdin)
for name, s in c["services"].items():
    b = s.get("build")
    if b:
        print(name, b["context"], b.get("dockerfile", "Dockerfile"), s.get("image") or "")
' | while read -r name ctx df img; do
    docker build -q --network host --build-arg HTTPS_PROXY="${HTTPS_PROXY:-}" \
      -f "$ctx/$df" -t "${img:-$project-$name}" "$ctx" >/dev/null
  done
}

case "${1:-}" in
  tools) tools ;;
  reset) daemon; reset ;;
  prebuild) prebuild "$2" ;;
  as) shift; sudo -u ana -i bash -c "export TZ=America/Sao_Paulo LC_ALL=C.UTF-8; $*" ;;
  *) sed -n '2,40p' "$0"; exit 1 ;;
esac
