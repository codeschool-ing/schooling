#!/usr/bin/env bash
# The laptop every transcript in aws-data was recorded on, and the AWS it talks to.
#
# THERE IS NO AWS ACCOUNT IN THIS COURSE, and nothing here is billed. The AWS the
# command line talks to is moto 5.2.3, the open-source imitation of the AWS API,
# answering on 127.0.0.1:4567: a Python program that keeps what it is told in
# memory and forgets it when it stops. The four AWS courses share that one
# environment; lesson 1 of this course gives its steps in brief.
#
#   sudo bash lab.sh tools               # once, with the network: build ~ana
#   sudo bash lab.sh run CAPTURES [ARG]  # a lesson's captures.sh, in a fresh lab
#
# THE LAB IS BUILT FROM THE LESSON ITSELF. `tools` runs the ```sh fences of
# lesson 1's section "the-lab" as they stand, so the setup a student follows is
# the one recorded; the first fence (apt-get, needing sudo) is checked rather
# than run. prices.py is read out of the example in "the-price-sheet", and run
# once so that its cache is full.
#
# `run` gives each capture a network namespace of its own: nothing it does can
# reach the internet, moto is always on 127.0.0.1:4567, and it is always empty
# when the capture starts, because each run starts a new one exactly as the
# student does in the other terminal. It also gets a copy-on-write layer over
# ~ana, thrown away afterwards, so no lesson inherits a file from another one
# and two captures can run at once. The variables the student exports in every
# terminal are read out of the lesson's sixth fence and sourced.
#
# What is STAGED rather than typed, and why:
#   - there is no user `ana` on the recording machine, and it was not allowed to
#     create one: everything runs as root with HOME=/home/ana, and the prompt is
#     printed as ana@laptop:~/aws$. No transcript shows an owner or a uid.
#   - python3 is Ubuntu 24.04's own 3.12. The recording machine points `python3`
#     at a newer one, so PYTHON3_DIR names a directory holding a `python3` link
#     to python3.12, and it goes first on the path.
#   - the recording machine reaches the internet through a proxy that re-signs
#     TLS, so the one capture that talks to the real AWS (lesson 1, "the-lab")
#     passes AWS_CA_BUNDLE pointing at that proxy's certificate. A student's
#     machine needs nothing of the kind.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=from-lessons.sh
. "$HERE/from-lessons.sh"
LAB_MD="$LESSONS/le-exbxwt0r/the-lab.md"
SHEET_MD="$LESSONS/le-exbxwt0r/the-price-sheet.md"
export HOME=/home/ana
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION \
  AWS_DEFAULT_REGION AWS_ENDPOINT_URL
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

tools() {
  for p in python3 python3-venv curl unzip jq; do
    installed "$p" || installed "${p/python3-venv/python3.12-venv}" \
      || { echo "install first, as in the first fence: $p"; exit 1; }
  done
  rm -rf /home/ana && mkdir -p /home/ana
  local scratch; scratch=$(mktemp -d)
  for n in 2 3 4; do
    fence "$LAB_MD" "$n" > "$scratch/fence-$n.sh"
    (cd /home/ana && bash -e "$scratch/fence-$n.sh") > "$scratch/fence-$n.log" 2>&1 \
      || { echo "fence $n of the-lab.md failed:"; cat "$scratch/fence-$n.log"; exit 1; }
  done
  example "$SHEET_MD" prices.py /home/ana/aws/prices.py
  (cd /home/ana/aws && venv/bin/python prices.py > /dev/null)
  rm -rf "$scratch"
  (cd /home/ana/aws && find . -mindepth 1 -maxdepth 1 | sort) > /home/ana/.baseline
  echo "lab built in /home/ana"
}

lab_run() {
  local script; script=$(realpath "$1"); shift
  [ -f /home/ana/.baseline ] || { echo "run tools first"; exit 1; }
  if [ "${LAB_NET:-}" = 1 ]; then
    # With the network and without moto, for the block that asks the real AWS.
    (cd /home/ana/aws && . <(fence "$LAB_MD" 6) \
      && AWS_CA_BUNDLE=/root/.ccr/ca-bundle.crt bash "$script" "$@")
    return
  fi
  # A copy-on-write layer over ~ana for this run alone, so runs can go in
  # parallel and none of them changes the lab the next one starts from.
  local layer; layer=$(mktemp -d /var/tmp/aws-data-run.XXXXXX)
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
. "$HERE/from-lessons.sh"
cd /home/ana/aws
comm -13 /home/ana/.baseline <(find . -mindepth 1 -maxdepth 1 | sort) | xargs -r rm -rf
rm -rf /home/ana/.aws
moto_start || exit 1
. <(fence "$LAB_MD" 6)
script=\$1; shift
bash "\$script" "\$@"
status=\$?
moto_stop
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
