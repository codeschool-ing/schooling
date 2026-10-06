#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# IT IS ONE LINUX MACHINE WITH A REAL DOCKER ENGINE ON IT. Nothing is emulated:
# dockerd, containerd and runc are the packages Docker publishes for Ubuntu,
# the images are the ones on Docker Hub, and every container in every lesson
# was started by the command the lesson shows. The machine is called `vm`, the
# student is `ana`, and her project is ~/shelf, the Go program in lab/shelf.
#
# WHAT IS STAGED, and why.
#   - Docker Hub answers this machine's anonymous pulls with
#     "429 Too Many Requests", so the daemon pulls Docker Hub images through
#     mirror.gcr.io, Google's public cache of Docker Hub. That is one line of
#     /etc/docker/daemon.json, "registry-mirrors", and lesson 6 shows the file.
#     The names, tags and digests are Docker Hub's; only the server that hands
#     over the bytes differs.
#   - Containers on this machine reach no network beyond it: the machine's
#     own traffic goes out through a proxy that re-signs TLS, and a container
#     does not trust that proxy. So nothing in this course installs a package
#     inside a container. shelf's one dependency, pgx, is vendored into the
#     project (vendor/, made by `go mod vendor` below), which Go builds from
#     without a network, and every lesson that would have shown an
#     `apt-get install` says so and shows why instead.
#   - Every run starts from a clean daemon: no containers, volumes, networks
#     or build cache, and only the images the lesson names in LAB_IMAGES,
#     pulled before the first command so a transcript is not a download log.
#     A lesson that shows a pull removes the image first.
#   - Ids that Docker invents (containers, images, networks) and every timing
#     are whatever that run produced, so a second run prints different ones.
#
#   sudo bash lab.sh tools       # once: the user, the daemon, the project
#   sudo bash lab.sh run CMD...  # CMD as ana, in /home/ana, on a clean daemon
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPT=/opt/docker-lab
PGX=v5.11.0

daemon() { # dockerd with the course's configuration, started if it is not running
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'JSON'
{
  "registry-mirrors": ["https://mirror.gcr.io"]
}
JSON
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
  # The socket takes the docker group when dockerd starts, so a daemon that
  # was running before the group existed is restarted once.
  if docker info >/dev/null 2>&1 && [ "$(stat -c %G /var/run/docker.sock)" != docker ]; then
    pkill -x dockerd; sleep 5
  fi
  daemon

  # shelf, as ana's repository: the source from lab/shelf, its dependency
  # vendored, and one commit at a fixed date so its hash is the same on every
  # machine that builds this lab.
  rm -rf "$OPT/shelf" && mkdir -p "$OPT"
  cp -r "$LAB/lab/shelf" "$OPT/shelf"
  (cd "$OPT/shelf" && GOFLAGS=-mod=mod go mod vendor)
  git -C "$OPT/shelf" init -q -b main
  git -C "$OPT/shelf" add -A
  GIT_AUTHOR_DATE='2026-09-01T10:00:00-03:00' GIT_COMMITTER_DATE='2026-09-01T10:00:00-03:00' \
    git -C "$OPT/shelf" -c user.name=Ana -c user.email=ana@example.com commit -q -m 'shelf: the catalogue over HTTP'
  chown -R root:root "$OPT"
}

reset() { # the daemon as it is on a machine where nothing has been done yet
  docker swarm leave --force >/dev/null 2>&1 || true
  local ids
  ids=$(docker ps -aq); [ -n "$ids" ] && docker rm -f $ids >/dev/null
  docker volume prune -af >/dev/null
  docker network prune -f >/dev/null
  docker builder prune -af >/dev/null
  local keep=" ${LAB_IMAGES:-} " img
  for img in $(docker image ls --format '{{.Repository}}:{{.Tag}}'); do
    case "$keep" in *" ${img#docker.io/library/} "*) ;; *) docker image rm -f "$img" >/dev/null 2>&1 || true ;; esac
  done
  docker image prune -f >/dev/null
  for img in ${LAB_IMAGES:-}; do docker pull -q "$img" >/dev/null; done
}

run() {
  daemon
  reset
  rm -rf /home/ana && mkdir -p /home/ana
  cp -r "$OPT/shelf" /home/ana/shelf
  chown -R ana:ana /home/ana
  cd /home/ana
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TZ="$TZ" LC_ALL="$LC_ALL" LAB_IMAGES="${LAB_IMAGES:-}" IN_LAB=1 "$@"
}

case "${1:-}" in
  tools) tools ;;
  run) shift; run "$@" ;;
  *) echo "usage: lab.sh tools | run CMD..." >&2; exit 2 ;;
esac
