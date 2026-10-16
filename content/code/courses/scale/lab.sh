#!/usr/bin/env bash
# The machine every transcript in the scale course was recorded on.
#
# THE STUDENT NEVER RECEIVES THIS FILE (C-40). Lesson 1 tells them to build a
# lab of their own: Ubuntu Server 24.04 in a virtual machine, with Docker
# Engine and its Compose plugin, Python 3 and curl. Every file of the project
# they measure, the `tickets` box office, is shown whole in a lesson, and
# `lab/extract.py` reads those files back OUT of the lessons' prose, so the
# file a capture runs is the file the student copies, byte for byte.
#
# THE RECORDING MACHINE is Ubuntu 24.04 (4 processors, 15 GB of memory) with
# Docker Engine 29.8.2 and Compose v5.6.0 from Docker's own repository, rather
# than a virtual machine inside it; a user `ana` exists so paths read as hers.
# Captures run as root with HOME=/home/ana.
#
# WHAT IS STAGED, AND WHY
#   - The images are pulled from mirror.gcr.io, Google's copy of Docker Hub,
#     and tagged with their Docker Hub names (postgres:16.15 and so on),
#     because Docker Hub itself answered this machine with 429 Too Many
#     Requests. The images are the same; the name the student pulls is the one
#     the lessons print.
#   - THIS MACHINE'S NETWORK RE-SIGNS TLS through a proxy with its own
#     certificate authority. `pip install` inside an image build would refuse
#     it, so `prepare` builds a local python:3.12.15-slim that is the real one
#     plus that certificate and PIP_CERT pointing at it. The Dockerfile the
#     lesson shows is used unchanged. A student's network needs none of this.
#   - The recording machine had no `ss`; `prepare` installs iproute2, which
#     an Ubuntu Server virtual machine already has.
#   - Every lesson's captures.sh starts from `stage N`: an empty ~/tickets
#     holding exactly the files lessons 1..N show, and no containers running.
#
#   bash lab.sh prepare           pull, tag, build the local base image (once)
#   bash lab.sh stage N [SLUG]    ~/tickets as lesson N leaves it (or as its
#                                 section SLUG leaves it), containers removed
#   bash lab.sh down              remove every container of the project
#
# Recorded with TZ=America/Sao_Paulo.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PROJECT=/home/ana/tickets
IMAGES="library/postgres:16.15 library/nginx:1.27.5 library/python:3.12.15-slim"

case "${1:-}" in
  prepare)
    for i in $IMAGES; do
      docker pull -q "mirror.gcr.io/$i" >/dev/null
      docker tag "mirror.gcr.io/$i" "${i#library/}"
    done
    d=$(mktemp -d)
    cp /root/.ccr/ca-bundle.crt "$d/proxy-ca.crt"
    printf '%s\n' 'FROM mirror.gcr.io/library/python:3.12.15-slim' \
      'COPY proxy-ca.crt /usr/local/share/ca-certificates/proxy-ca.crt' \
      'ENV PIP_CERT=/usr/local/share/ca-certificates/proxy-ca.crt' > "$d/Dockerfile"
    docker build -q -t python:3.12.15-slim "$d" >/dev/null
    rm -rf "$d"
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    command -v ss >/dev/null || apt-get install -y iproute2 >/dev/null
    ;;
  stage)
    n=${2:?lesson number}
    [ -d "$PROJECT" ] && (cd "$PROJECT" && docker compose down -v --remove-orphans >/dev/null 2>&1 || true)
    rm -rf "$PROJECT"; mkdir -p "$PROJECT"
    python3 "$HERE/lab/extract.py" "$HERE" "$PROJECT" "$n" ${3:-} >/dev/null
    chown -R ana: "$PROJECT"
    ;;
  down)
    [ -d "$PROJECT" ] && (cd "$PROJECT" && docker compose down -v --remove-orphans >/dev/null 2>&1 || true)
    ;;
  *) sed -n '2,40p' "$0"; exit 2 ;;
esac
