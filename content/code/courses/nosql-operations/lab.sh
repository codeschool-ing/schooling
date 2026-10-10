#!/usr/bin/env bash
# The machine every transcript in nosql-operations was recorded on.
#
# ONE UBUNTU 24.04 MACHINE WITH A REAL DOCKER ENGINE ON IT, and the three
# official images: mongo:8.0, redis:7.4 and cassandra:5.0 (and postgres:16,
# which lesson 22 sets beside them). Nothing is emulated. Every container in
# every lesson was started by the command the lesson shows, every replica set,
# sentinel and cluster was formed by the commands the lesson shows, and every
# line of data was written by a statement or a generator the lesson shows. The
# machine is called `vm` and the student is `ana`, as lesson 1 builds it.
#
# THE STUDENT NEVER RECEIVES THIS FILE, capture.sh or lab/. They are how the
# author proves a transcript was run. Files a lesson hands the student are
# taken back out of the lesson's own .md by lab/fences.py, so the file that was
# run is the file the page shows.
#
# WHAT IS STAGED, and why.
#   - Each capture run starts from a clean daemon: no containers, volumes or
#     networks (anything named x-* is left alone: that is the author's scratch
#     space, never a lesson's). The images are pulled once by `tools`, so a
#     transcript is not a download log; a lesson that shows a pull shows the
#     pull of an image that was already there, and says so.
#   - The Docker installation itself (lesson 1) was on the machine before the
#     course began; the lesson marks its install commands as not run here.
#   - An interactive client (mongosh, redis-cli, cqlsh) is fed its lines
#     through a pipe by lab/session.py, one line at a time, waiting for each
#     answer. The prompt in front of each line is the one the client printed
#     (mongosh, cqlsh) or, for redis-cli, which prints none through a pipe, the
#     host:port it was connected to. A student typing at a terminal sees the
#     same answers; colours and line editing are a terminal's and not shown.
#   - ObjectIds, host ids, timings, addresses inside the Docker network and
#     every figure that depends on the clock are whatever that run produced,
#     so a second run prints different ones. The lessons quote the run that
#     was recorded.
#
#   sudo bash lab.sh tools        once: the user, the daemon, the images
#   bash capture.sh-using script  re-runs itself here as: lab.sh run CMD...
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGES="mongo:8.0 redis:7.4 cassandra:5.0 postgres:16"

daemon() { # dockerd, started if it is not running: this machine has no systemd
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
  if docker info >/dev/null 2>&1 && [ "$(stat -c %G /var/run/docker.sock)" != docker ]; then
    pkill -x dockerd; sleep 5
  fi
  daemon
  for img in $IMAGES; do docker pull -q "$img" >/dev/null; done
}

reset() { # the daemon as it is before a lesson starts, scratch (x-*) aside
  local c
  for c in $(docker ps -a --format '{{.Names}}'); do
    case "$c" in x-*) ;; *) docker rm -f "$c" >/dev/null ;; esac
  done
  for c in $(docker volume ls -q); do
    case "$c" in x-*) ;; *) docker volume rm -f "$c" >/dev/null ;; esac
  done
  for c in $(docker network ls --format '{{.Name}}'); do
    case "$c" in bridge|host|none|x-*) ;; *) docker network rm "$c" >/dev/null ;; esac
  done
}

run() {
  # One capture at a time: every lesson uses the same container names.
  exec 8>/var/tmp/nosql-lab.lock
  flock 8
  daemon
  reset
  rm -rf /home/ana && mkdir -p /home/ana && chown ana:ana /home/ana
  cd /home/ana
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TZ="$TZ" LC_ALL="$LC_ALL" IN_LAB=1 "$@" || rc=$?
  rc=${rc:-0}
  reset
  return $rc
}

case "${1:-}" in
  tools) tools ;;
  run) shift; run "$@" ;;
  *) echo "usage: lab.sh tools | run CMD..." >&2; exit 2 ;;
esac
