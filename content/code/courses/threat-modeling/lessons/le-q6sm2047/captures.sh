#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of threat-modeling, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it.
#
#   sudo cp ../../lab.sh /var/tmp/tmlab.sh && sudo cp -r ../../lab /var/tmp/lab
#   sudo bash captures.sh        # as root; the commands themselves run as ana
#
#
# What is STAGED rather than typed, and not shown in the lesson: the workspace
# as it was at the end of this lesson, rebuilt by lab.sh, which holds
# mapping.csv and crosswalk.py exactly as the lesson prints them. Every line
# after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3 and pytm 1.4.0,
# TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
AS_ANA=${AS_ANA:-/var/tmp/as-ana.sh}   # runuser -u ana, with the proxy's CA readable
run() {   # run DIR 'command': ana's prompt in DIR with the venv active, then the output
  local dir=$1; shift
  printf '(.venv) ana@vm:%s$ %s\n' "${dir/#\/home\/ana/\~}" "$*"
  "$AS_ANA" env GIT_AUTHOR_DATE='2026-10-05 14:00:00 -0300' GIT_COMMITTER_DATE='2026-10-05 14:00:00 -0300' \
    bash -c "cd $dir && . /home/ana/tm/.venv/bin/activate && $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

"$AS_ANA" bash /var/tmp/tmlab.sh reset 13   # lessons 1 to 12, and this lesson's files
M=/home/ana/tm/portal-model

block 'mapping'
run $M 'head -4 mapping.csv'
run $M 'python3 crosswalk.py'

block 'iso'
run $M 'python3 crosswalk.py iso27001'

block 'csf'
run $M 'python3 crosswalk.py csf'
