#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of threat-modeling, as a script that produces them.
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
# controls.csv and prioritise.py exactly as the lesson prints them. The
# folder after/ is a scratch folder the lesson makes and deletes. Every line
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
  "$AS_ANA" env GIT_AUTHOR_DATE='2026-09-29 11:00:00 -0300' GIT_COMMITTER_DATE='2026-09-29 11:00:00 -0300' \
    bash -c "cd $dir && . /home/ana/tm/.venv/bin/activate && $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

"$AS_ANA" bash /var/tmp/tmlab.sh reset 11   # lessons 1 to 10, and this lesson's two files
M=/home/ana/tm/portal-model

block 'rank'
run $M 'python3 prioritise.py'
block 'overlap'
run $M 'mkdir after'
run $M 'python3 prioritise.py C1 C2 > after/risks.csv'
run $M 'cd after && python3 ../risk.py | grep T03'
block 'plan'
run $M 'python3 prioritise.py C5 C1 C8 C4 > after/risks.csv'
run $M 'cd after && python3 ../fair.py | tail -7'
run $M 'python3 prioritise.py C5 C1 C8 C4 C3 C9 C10 C7 C2 > after/risks.csv'
run $M 'cd after && python3 ../fair.py | tail -12'
run $M 'rm -r after'
