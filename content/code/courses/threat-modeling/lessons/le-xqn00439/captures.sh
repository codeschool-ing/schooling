#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of threat-modeling, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it.
#
#   sudo cp ../../lab.sh /var/tmp/tmlab.sh && sudo cp -r ../../lab /var/tmp/lab
#   sudo bash captures.sh        # as root; the commands themselves run as ana
#
#
# What is STAGED rather than typed, and not shown in the lesson: the workspace
# rebuilt by lab.sh at four points of this lesson's history, one per block, so
# each command meets the repository as it was at that commit. The files are the
# ones the lesson prints. The dates passed to check_model.py and acceptances.py
# are the day of the commit, and, in the last block, a day in December chosen
# to show a review falling due. Every line after a prompt is what the command
# printed.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3 and pytm 1.4.0,
# TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
AS_ANA=${AS_ANA:-/var/tmp/as-ana.sh}   # runuser -u ana, with the proxy's CA readable
run() {   # run DIR 'command': ana's prompt in DIR with the venv active, then the output
  local dir=$1; shift
  printf '(.venv) ana@vm:%s$ %s\n' "${dir/#\/home\/ana/\~}" "$*"
  "$AS_ANA" env GIT_AUTHOR_DATE='2026-10-12 11:15:00 -0300' GIT_COMMITTER_DATE='2026-10-12 11:15:00 -0300' \
    bash -c "cd $dir && . /home/ana/tm/.venv/bin/activate && $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

M=/home/ana/tm/portal-model
at() { "$AS_ANA" bash /var/tmp/tmlab.sh reset "$1"; }   # the repository after commit $1

block 'renewed'
at 15
run $M 'head -9 decisions/RA-003-cancellation-record-renewed.md'
run $M 'python3 acceptances.py 2026-10-09'

block 'soc2'
at 16
run $M 'tail -2 threats.csv'

block 'check-fails'
at 17
run $M 'cat baseline.txt'
run $M 'sh check.sh 2026-10-12; echo "exit $?"'

block 'check-passes'
at 18
run $M 'cat baseline.txt'
run $M 'sh check.sh 2026-10-12; echo "exit $?"'

block 'december'
run $M 'python3 check_model.py 2026-12-16; echo "exit $?"'
run $M 'git log --format="%ad %s" --date=short -- threats.csv requirements.csv decisions'
