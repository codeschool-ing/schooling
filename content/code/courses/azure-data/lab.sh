#!/usr/bin/env bash
# The laptop every transcript in azure-data was recorded on, and the Azure it
# talks to.
#
# THERE IS NO AZURE ACCOUNT IN THIS COURSE, and nothing here is billed. What
# answers is Microsoft's own emulators, run as containers by Docker Compose on
# the same machine: Azurite for Blob, Queue and Table storage, the Cosmos DB
# emulator (vNext, the Linux one), the Event Hubs emulator, and SQL Server
# itself, plus PostgreSQL and Redis from their own projects. No emulator
# answers Azure's control plane, so nothing here creates a storage account, a
# server or a workspace; Terraform checks what declares them, offline.
#
#   sudo bash lab.sh tools               # once, with the network: build ~ana
#   sudo bash lab.sh run CAPTURES [ARG]  # a lesson's captures.sh
#
# THE LAB IS BUILT FROM THE LESSON ITSELF. `tools` runs the ```sh fences of
# lesson 1's section "the-lab" as they stand, so the setup a student follows is
# the one recorded; the first fence (apt-get, needing sudo) is checked rather
# than run, and the two files the student saves (compose.yaml and the Event
# Hubs configuration) are read out of the same section.
#
# `run` serialises captures with a lock, because the emulators listen on fixed
# ports of 127.0.0.1 exactly as they do on a student's machine, and two
# captures at once would talk to each other's. Each capture starts the
# emulators it needs itself, empty, with `services` from from-lessons.sh, and
# the files an earlier capture left in ~/azure are removed first. The variables
# the student exports in every terminal are read out of the lesson's seventh
# fence and sourced.
#
# What is STAGED rather than typed, and why:
#   - there is no user `ana` on the recording machine, and it was not allowed to
#     create one: everything runs as root with HOME=/home/ana, and the prompt is
#     printed as ana@laptop:~/azure$. No transcript shows an owner or a uid.
#   - python3 is Ubuntu 24.04's own 3.12. The recording machine points `python3`
#     at a newer one, so a directory holding a `python3` link to python3.12 goes
#     first on the path.
#   - Docker is Docker Engine 29.9.2 from Docker's own packages, where a student
#     on Ubuntu installs Ubuntu's docker.io. The commands and the containers are
#     the same; a transcript that prints Docker's version would differ, and none
#     does.
#   - the emulators are started by `services` before a capture's first command,
#     where the student types `docker compose up -d` with the profile the lesson
#     names. The wait until each one answers is not shown.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=from-lessons.sh
. "$HERE/from-lessons.sh"
LAB_MD="$LESSONS/le-w6h119dd/the-lab.md"
export HOME=/home/ana
unset AZURE_STORAGE_CONNECTION_STRING AZURE_STORAGE_ACCOUNT AZURE_STORAGE_KEY \
  AZURE_CONFIG_DIR AZURE_SUBSCRIPTION_ID ARM_SUBSCRIPTION_ID
PY312=/var/tmp/azure-data-python
mkdir -p "$PY312" && ln -sf /usr/bin/python3.12 "$PY312/python3"
export PATH="$PY312:$PATH"

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

tools() {
  for p in python3 python3-venv curl unzip jq; do
    installed "$p" || installed "${p/python3-venv/python3.12-venv}" \
      || { echo "install first, as in the first fence: $p"; exit 1; }
  done
  docker compose version > /dev/null || { echo "no docker compose"; exit 1; }
  rm -rf /home/ana && mkdir -p /home/ana
  local scratch; scratch=$(mktemp -d)
  for n in 2 3 4; do
    fence "$LAB_MD" "$n" > "$scratch/fence-$n.sh"
    (cd /home/ana && bash -e "$scratch/fence-$n.sh") > "$scratch/fence-$n.log" 2>&1 \
      || { echo "fence $n of the-lab.md failed:"; cat "$scratch/fence-$n.log"; exit 1; }
  done
  mkdir -p /home/ana/azure/eventhubs
  file_fence "$LAB_MD" compose.yaml > /home/ana/azure/compose.yaml
  file_fence "$LAB_MD" eventhubs/config.json > /home/ana/azure/eventhubs/config.json
  fence "$LAB_MD" 5 > "$scratch/fence-5.sh"
  (cd /home/ana/azure && bash -e "$scratch/fence-5.sh") > "$scratch/fence-5.log" 2>&1 \
    || { echo "fence 5 of the-lab.md failed:"; cat "$scratch/fence-5.log"; exit 1; }
  rm -rf "$scratch"
  (cd /home/ana/azure && find . -mindepth 1 -maxdepth 1 | sort) > /home/ana/.baseline
  echo "lab built in /home/ana"
}

lab_run() {
  local script; script=$(realpath "$1"); shift
  [ -f /home/ana/.baseline ] || { echo "run tools first"; exit 1; }
  exec 9> /var/tmp/azure-data-lab.lock
  flock 9
  cd /home/ana/azure
  comm -13 /home/ana/.baseline <(find . -mindepth 1 -maxdepth 1 | sort) | xargs -r rm -rf
  # shellcheck disable=SC1090
  . <(fence "$LAB_MD" 7)
  local status=0
  bash "$script" "$@" || status=$?
  services_down
  return $status
}

case "${1:-}" in
  tools) tools ;;
  run) shift; lab_run "$@" ;;
  *) echo "usage: lab.sh tools | lab.sh run CAPTURES [ARG...]"; exit 2 ;;
esac
