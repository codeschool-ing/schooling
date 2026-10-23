#!/usr/bin/env bash
# The machine every transcript in secure-code was recorded on, and how to
# repeat a recording.
#
# THE STUDENT NEVER RECEIVES THIS FILE. Lesson 1 builds the workspace by hand,
# step by step, and every later lesson shows in full each file it adds. This
# script, lab/ beside it and each lesson's captures.sh exist so the captures
# can be repeated and checked; none of them is a step of the course.
#
# THE WORKSPACE. ~/sc on a computer with Python 3.12 or later: one virtual
# environment, ~/sc/.venv, and one folder per lesson (~/sc/cancel,
# ~/sc/booking, ...), each a git repository of its own holding one small
# Flask application of Vereda Fisioterapia's patient portal and its tests.
#
# WHAT IS STAGED, AND WHY
#   - The recording computer is Ubuntu 24.04 with Python 3.13 as python3, and
#     it could not create a user account. So every command runs as root, in a
#     private mount namespace (unshare --mount) where LAB_HOME/ana is bound
#     at /home/ana: the paths the programs print are /home/ana/sc/..., as they are on
#     the machine the lessons describe, and the prompt `ana@vm` is printed by
#     capture-lib.sh rather than by a shell. Nothing in the course depends on
#     being root, and nothing printed shows the user's name.
#   - PIP_DISABLE_PIP_VERSION_CHECK=1, so pip does not append a notice whose
#     content depends on the day the recording was made.
#   - TZ=America/Sao_Paulo and LC_ALL=C.UTF-8. Every date the applications
#     carry is fixed in their own code or in the test that sets it.
#   - A capture that starts a server takes a lock first, so two captures run
#     at the same time cannot meet on port 5000.
#
#   bash lab.sh fresh          delete the workspace: the next lesson-1
#                              capture starts from no ~/sc at all
#   bash lab.sh shell          a shell inside the lab, as the captures see it
#   bash lab.sh capture N      run lesson N's captures.sh, output to stdout
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export LAB_HOME=${LAB_HOME:-/var/tmp/secure-code-home}
mkdir -p "$LAB_HOME/ana"

case "${1:-}" in
  fresh)   rm -rf "$LAB_HOME/ana/sc" ;;
  shell)   exec unshare --mount bash -c "mount -t tmpfs tmpfs /home && mkdir /home/ana && mount --bind '$LAB_HOME/ana' /home/ana && cd /home/ana && HOME=/home/ana exec bash" ;;
  capture)
    id=$(python3 -c "import json,sys; print(json.load(open('$here/course.json'))['topics'][int(sys.argv[1])-1]['id'])" "$2")
    exec bash "$here/lessons/$id/captures.sh" ;;
  *) sed -n '2,40p' "$0"; exit 2 ;;
esac
