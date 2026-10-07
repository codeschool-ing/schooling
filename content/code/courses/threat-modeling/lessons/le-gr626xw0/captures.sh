#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of threat-modeling, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it.
#
#   sudo bash captures.sh        # as root; the commands themselves run as ana
#
# It runs the steps of "Your workspace" in order, as the user ana, in her home
# directory, starting from no ~/tm at all. What is NOT shown: installing
# python3, python3-venv and git with apt, because the recording machine already
# had them; the lesson says so where it gives the command. pip reached PyPI
# through the recording machine's proxy, which is configured in the
# environment and prints nothing.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
AS_ANA=${AS_ANA:-/var/tmp/as-ana.sh}   # runuser -u ana, with the proxy's CA readable
VENV=0
run() {   # run DIR 'command': print ana's prompt in DIR, then what the command printed
  local dir=$1; shift
  local shown=${dir/#\/home\/ana/\~}
  local pre=''; [ "$VENV" = 1 ] && pre='(.venv) '
  printf '%sana@vm:%s$ %s\n' "$pre" "$shown" "$*"
  local act=''; [ "$VENV" = 1 ] && act='. /home/ana/tm/.venv/bin/activate && '
  "$AS_ANA" bash -c "cd $dir && $act$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

"$AS_ANA" rm -rf /home/ana/tm /home/ana/.cache/pip   # a first install, as a student has

block 'versions'
run /home/ana 'python3 --version'
run /home/ana 'git --version'

block 'venv'
run /home/ana 'mkdir tm'
run /home/ana/tm 'python3 -m venv .venv'
run /home/ana/tm '. .venv/bin/activate'
VENV=1
run /home/ana/tm 'pip install --progress-bar off pytm==1.4.0'
run /home/ana/tm 'pip show pytm'

block 'repo'
run /home/ana/tm 'git init -b main portal-model'
run /home/ana/tm 'ls -A'

block 'failures'
run /home/ana/tm 'pip install --progress-bar off pytm==9.9.9'
run /home/ana/tm 'deactivate'
VENV=0
run /home/ana/tm "python3 -c 'import pytm'"
