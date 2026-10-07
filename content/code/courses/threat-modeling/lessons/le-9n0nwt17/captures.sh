#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of threat-modeling, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it.
#
#   sudo cp ../../lab.sh /var/tmp/tmlab.sh && sudo cp -r ../../lab /var/tmp/lab
#   sudo bash captures.sh        # as root; the commands themselves run as ana
#
# What is STAGED rather than typed, and not shown in the lesson: the workspace
# of lesson 1, rebuilt by lab.sh; then an empty portal-model repository holding
# .gitignore, model.py and flows.py exactly as the section prints them, which
# is ana having typed them in. ana's git identity (user.name ana, user.email
# ana@vereda.example) was set with `git config --global` beforehand, and the
# commit's date is fixed to the one lab.sh gives it, so the hash in the lesson
# is the hash the lab produces. Every line after a prompt is what the command
# printed.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
AS_ANA=${AS_ANA:-/var/tmp/as-ana.sh}   # runuser -u ana, with the proxy's CA readable
LAB=/var/tmp/lab
run() {   # run DIR 'command': ana's prompt in DIR with the venv active, then the output
  local dir=$1; shift
  printf '(.venv) ana@vm:%s$ %s\n' "${dir/#\/home\/ana/\~}" "$*"
  "$AS_ANA" env GIT_AUTHOR_DATE='2026-09-01 10:00:00 -0300' GIT_COMMITTER_DATE='2026-09-01 10:00:00 -0300' \
    bash -c "cd $dir && . /home/ana/tm/.venv/bin/activate && $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

"$AS_ANA" bash /var/tmp/tmlab.sh reset
"$AS_ANA" git config --global user.name ana
"$AS_ANA" git config --global user.email ana@vereda.example
"$AS_ANA" bash -c "rm -rf ~/tm/portal-model && git init -q -b main ~/tm/portal-model &&
  cd ~/tm/portal-model && printf '__pycache__/\nmodel.json\n' > .gitignore &&
  cp $LAB/model.py $LAB/flows.py ."
M=/home/ana/tm/portal-model

block 'run'
run $M 'ls -A'
run $M 'python3 model.py --json model.json'
run $M 'python3 flows.py model.json'

block 'commit'
run $M 'git status --short'
run $M 'git add .gitignore model.py flows.py'
run $M "git commit -m 'Draw the portal as a data flow diagram'"

"$AS_ANA" bash /var/tmp/tmlab.sh reset >/dev/null
