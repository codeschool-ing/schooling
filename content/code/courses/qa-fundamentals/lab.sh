#!/usr/bin/env bash
# The machine every transcript in qa-fundamentals was recorded on, built the
# way lesson 1 teaches a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1, section `the-lab`, gives them the
# commands, and every program the course runs is printed whole in the lesson
# that uses it. This script runs that section's `sh` fences, read out of the
# lesson itself and in order, so a transcript is what the student's machine
# prints; `lab/extract.py` reads the programs out of the lessons the same way.
#
# ONE LINUX COMPUTER AND ONE PERSON. lia has just joined Cine Aurora, a
# three-screen cinema in Belo Horizonte that does not exist, as its first
# tester. The system under test is the ticket shop's price rule, a program of
# about forty lines that lesson 1 prints, and what the later lessons build
# around it. Nothing reads a clock or a network, so every run prints the same.
#
#   ~/aurora         the working directory: the programs and what they write
#   ~/aurora/.venv   Python 3.12 with behave, pinned
#
# STAGED rather than typed, because Ubuntu Server ships them and the container
# image leaves them out: python3, sudo, and the user lia in the group sudo as
# the first user of an Ubuntu Server install is. Also staged: the file
# ~/.sudo_as_admin_successful, which silences a two-line note a real machine
# prints once. The machine is a container rather than a virtual machine because
# the userland is the same and a container starts clean every time.
#
# APT and pip reach the network through this recording machine's HTTPS proxy
# and its certificate (PROXY and CA below); that is the recording machine's,
# not a step of the lesson.
#
#   bash lab.sh image                 build aurora-lab:base and aurora-lab:ready
#   bash lab.sh run LESSON < SCRIPT   run SCRIPT as lia in ~/aurora, in a fresh
#                                     container, with every program the course
#                                     printed up to and including LESSON
#   bash lab.sh bare < SCRIPT         the same in aurora-lab:base, before the
#                                     setup, for lesson 1's failures
#
# SCRIPT may call `on 'COMMAND'`, which prints the prompt and the command and
# then runs it in an interactive bash, the shell lesson 1's ~/.bashrc lines
# make; `block NAME` prints a separator the author splices by; `version NAME N`
# puts the Nth version a lesson printed of NAME in place, for a lesson that
# shows one file growing.
#
# Recorded on Ubuntu 24.04 with Python 3.12.3 and behave 1.3.3.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON1=$HERE/lessons/le-0rz35yja
PROXY=${PROXY:-${HTTPS_PROXY:-}}
CA=${CA:-/root/.ccr/ca-bundle.crt}

net() {
  if [ -n "$PROXY" ]; then
    printf -- '--network host -e HTTPS_PROXY=%s -e https_proxy=%s -e PIP_CERT=/ca.crt -e SSL_CERT_FILE=/ca.crt -v %s:/ca.crt:ro' \
      "$PROXY" "$PROXY" "$CA"
  fi
}

# The `sh` fences of section `the-lab`, in order: what the student types.
setup_commands() {
  awk '/^```sh$/{on=1;next} /^```$/{on=0} on' "$LESSON1/the-lab.md"
}

HELPERS=$(cat <<'H'
export LC_ALL=C.UTF-8 COLUMNS=100
on() {
  printf 'lia@lab:%s$ %s\n' "$(pwd | sed "s|^$HOME|~|")" "$1"
  bash -ic "$1" 2>&1 | grep -v '^bash: \(cannot set terminal\|no job control\)' || true
}
block() { printf '##### %s\n' "$1"; }
version() { cp "$HOME/.versions/$1@$2" "$1"; }
H
)

image() {
  local base
  base=$(cat <<'B'
set -e
export DEBIAN_FRONTEND=noninteractive
if [ -n "${HTTPS_PROXY:-}" ]; then
  sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources
  printf 'Acquire::https::Proxy "%s";\nAcquire::https::CAInfo "/ca.crt";\n' "$HTTPS_PROXY" \
    > /etc/apt/apt.conf.d/99proxy
fi
apt-get update -qq >/dev/null
apt-get install -y -qq python3 sudo >/dev/null 2>&1
userdel -r ubuntu >/dev/null 2>&1 || true
useradd -m -s /bin/bash -G sudo lia
echo 'lia ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/lia
touch /home/lia/.sudo_as_admin_successful
B
)
  docker rm -f aurora-build >/dev/null 2>&1 || true
  # shellcheck disable=SC2046
  docker run --name aurora-build --hostname lab $(net) ubuntu:24.04 bash -c "$base"
  docker commit aurora-build aurora-lab:base >/dev/null
  docker rm aurora-build >/dev/null
  # shellcheck disable=SC2046
  docker run --name aurora-build --hostname lab $(net) -u lia -w /home/lia aurora-lab:base \
    bash -c "set -e; export PIP_PROGRESS_BAR=off; $(setup_commands)"
  docker commit aurora-build aurora-lab:ready >/dev/null
  docker rm aurora-build >/dev/null
  echo 'aurora-lab:base and aurora-lab:ready built'
}

# Every lesson written up to and including $1, in the order of the topics,
# which is the course's order whether or not `lessons` names it yet.
lessons_upto() {
  python3 - "$HERE" "$1" <<'P'
import json, os, sys
here, last = sys.argv[1], sys.argv[2]
for t in json.load(open(f'{here}/course.json'))['topics']:
    l = t['id']
    if os.path.isdir(f'{here}/lessons/{l}'):
        print(f'{here}/lessons/{l}')
    if l == last:
        break
P
}

run_in() {
  local img=$1 lesson=${2:-} work
  work=$(mktemp -d); chmod 755 "$work"
  if [ -n "$lesson" ]; then
    local mds=()
    for d in $(lessons_upto "$lesson"); do
      while IFS= read -r m; do mds+=("$m"); done < <(python3 "$HERE/lab/order.py" "$d")
    done
    python3 "$HERE/lab/extract.py" "$work" "${mds[@]}"
    chmod -R a+rX "$work"
  fi
  local script
  script=$(cat)
  # shellcheck disable=SC2046
  docker run --rm -i --hostname lab $(net) -u lia -w /home/lia \
    -v "$work:/files:ro" "$img" bash -c "
mkdir -p ~/aurora ~/.versions && cp -r /files/. ~/aurora/ 2>/dev/null; mv ~/aurora/.versions/* ~/.versions/ 2>/dev/null; rmdir ~/aurora/.versions 2>/dev/null; cd ~/aurora
$HELPERS
$script" 2>&1
  rm -rf "$work"
}

case ${1:-} in
  image) image ;;
  run) run_in aurora-lab:ready "${2:?lesson id}" ;;
  bare) run_in aurora-lab:base "" ;;
  *) echo "usage: lab.sh image | run LESSON < SCRIPT | bare < SCRIPT" >&2; exit 2 ;;
esac
