#!/usr/bin/env bash
# The laptop every transcript in gcp-data was recorded on, and the Google Cloud
# it talks to.
#
# THERE IS NO GOOGLE CLOUD ACCOUNT IN THIS COURSE, and nothing here is billed.
# What answers instead are the emulators: fake-gcs-server 1.54.0 for Cloud
# Storage, and the Pub/Sub, Firestore, Bigtable and Spanner emulators that ship
# as components of the Google Cloud CLI 591.0.0. Each is a program on
# 127.0.0.1 that keeps what it is told in memory and forgets it when it stops.
# Lesson 1 of this course builds the environment; the other GCP courses share it.
#
#   sudo FAKE_GCS_BIN=FILE bash lab.sh tools   # once, with the network: build ~ana
#   sudo bash lab.sh run CAPTURES [ARG]        # a lesson's captures.sh, in a fresh lab
#   sudo WHEELS=DIR bash lab.sh run …          # pip inside the run reads DIR only
#
# THE LAB IS BUILT FROM THE LESSON ITSELF. `tools` runs the ```sh fences of
# lesson 1's section "the-lab" as they stand, so the setup a student follows is
# the one recorded; the first fence (apt-get, needing sudo) is checked rather
# than run.
#
# `run` gives each capture a network namespace of its own: nothing it does can
# reach the internet, every emulator port is on 127.0.0.1 and starts empty, and
# the proxy settings of the recording machine are not in the environment at all.
# It also gets a copy-on-write layer over ~ana, thrown away afterwards, so no
# lesson inherits a file from another one and two captures can run at once. The
# variables the student exports in every terminal are read out of the lesson's
# sixth fence and sourced. Each captures.sh starts the emulators it needs.
#
# What is STAGED rather than typed, and why:
#   - there is no user `ana` on the recording machine: everything runs as root
#     with HOME=/home/ana, and the prompt is printed as ana@laptop:~/gcp$. No
#     transcript shows an owner or a uid.
#   - the third fence downloads fake-gcs-server from its GitHub release, and the
#     recording machine cannot reach GitHub's downloads. FAKE_GCS_BIN is the same
#     tag, v1.54.0, built from its source with `go install
#     github.com/fsouza/fake-gcs-server@v1.54.0` (Go 1.25.0); the release
#     archive's name was read from that tag's ci/.goreleaser.yml.
#   - python3 is Ubuntu 24.04's own 3.12. The recording machine points `python3`
#     at a newer one, so PYTHON3_DIR names a directory holding a `python3` link
#     to python3.12, and it goes first on the path.
#   - pip inside a run has no network; a lesson that installs a package has its
#     wheels fetched beforehand with `pip download` into WHEELS.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=from-lessons.sh
. "$HERE/from-lessons.sh"
export HOME=/home/ana
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

tools() {
  for p in python3 python3-venv curl openjdk-21-jre-headless; do
    installed "$p" || installed "${p/python3-venv/python3.12-venv}" \
      || { echo "install first, as in the first fence: $p"; exit 1; }
  done
  [ -x "${FAKE_GCS_BIN:-}" ] || { echo "FAKE_GCS_BIN must name the v1.54.0 binary"; exit 1; }
  rm -rf /home/ana && mkdir -p /home/ana
  local scratch; scratch=$(mktemp -d)
  for n in 2 4; do
    fence "$LAB_MD" "$n" > "$scratch/fence-$n.sh"
    (cd /home/ana && bash -e "$scratch/fence-$n.sh") > "$scratch/fence-$n.log" 2>&1 \
      || { echo "fence $n of the-lab.md failed:"; cat "$scratch/fence-$n.log"; exit 1; }
    [ "$n" = 2 ] && install -m 755 "$FAKE_GCS_BIN" /home/ana/gcp/bin/fake-gcs-server
  done
  rm -rf "$scratch"
  (cd /home/ana/gcp && find . -mindepth 1 -maxdepth 1 | sort) > /home/ana/.baseline
  echo "lab built in /home/ana"
}

lab_run() {
  local script; script=$(realpath "$1"); shift
  [ -f /home/ana/.baseline ] || { echo "run tools first"; exit 1; }
  local layer; layer=$(mktemp -d /var/tmp/gcp-data-run.XXXXXX)
  mkdir -p "$layer/upper" "$layer/work"
  unshare -m -n bash -s "$script" "$@" <<EOF
set -uo pipefail
mount -t overlay overlay -o lowerdir=/home/ana,upperdir=$layer/upper,workdir=$layer/work /home/ana || exit 1
python3 -c '
import socket, fcntl, struct
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ifr = struct.pack("16sH14s", b"lo", 0, b"\0" * 14)
flags = struct.unpack("16sH14s", fcntl.ioctl(s, 0x8913, ifr))[1]
fcntl.ioctl(s, 0x8914, struct.pack("16sH14s", b"lo", flags | 1, b"\0" * 14))'
for v in \$(env | grep -i -E '^[a-z_]*proxy=|^(CLOUDSDK|GOOGLE|AWS|GH|GITHUB|JAVA_TOOL|CCR|GLOBAL_AGENT|npm_config|YARN|DOCKER)_' | cut -d= -f1); do unset \$v; done
if [ -n "${WHEELS:-}" ]; then export PIP_NO_INDEX=1 PIP_FIND_LINKS=${WHEELS:-}; fi
. "$HERE/from-lessons.sh"
cd /home/ana/gcp
comm -13 /home/ana/.baseline <(find . -mindepth 1 -maxdepth 1 | sort) | xargs -r rm -rf
. <(fence "\$LAB_MD" 6)
script=\$1; shift
bash "\$script" "\$@"
status=\$?
for e in gcs pubsub firestore bigtable spanner; do emu_stop \$e; done
exit \$status
EOF
  local status=$?
  rm -rf "$layer"
  return $status
}

case "${1:-}" in
  tools) tools ;;
  run) shift; lab_run "$@" ;;
  *) echo "usage: lab.sh tools | lab.sh run CAPTURES [ARG...]"; exit 2 ;;
esac
