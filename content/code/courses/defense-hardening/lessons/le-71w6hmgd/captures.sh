#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by ../../lab.sh from
# the hostlab.sh lesson 1 shows: trap, desk and web are started fresh. A line
# that starts with ana@trap ran on the machine called trap, as ana.
#
# What is STAGED rather than typed:
# - bait.py (on trap) and canary.sh (on web) are written into ana's home from
#   this lesson's own Markdown, byte for byte as the copy button hands them
#   over: the student pastes them.
# - every "touch" is the student's own: a connection from desk, a scan of the
#   student's own trap, a file opened by the student, a login tried with a
#   name that exists nowhere. The credentials in the bait file are invented
#   and open nothing.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
put() {   # put HOST USER PATH FILE: write a file the lesson shows onto a machine
  python3 /var/tmp/dh/tools/fromlesson.py "$here" "$4" | lab exec "$1" "$2" "cat > $3"
}

lab up trap desk web >/dev/null 2>&1
put trap ana /home/ana/bait.py bait.py
put web ana /home/ana/canary.sh canary.sh

block bait-start
on trap 'sudo systemd-run -q --unit bait python3 /home/ana/bait.py'
on trap "sleep 1; sudo ss -Htlnp | grep python3 | awk '{print \$4}'"

block touch
on desk 'nc -zv -w2 trap 445 2>&1'

block alert
on trap 'sudo journalctl -t bait -o short-iso --no-pager'
on trap 'cat /var/log/bait.jsonl'

block scan
on desk 'nmap -Pn -p 1-3400 trap | grep -E "^[0-9]+/tcp"'
on trap 'sudo journalctl -t bait -o cat --no-pager | sort | uniq -c'

block token
on web 'sudo mkdir -p /srv/portal/old-backup'
on web 'printf "# old backup job, kept for reference\nDB_HOST=db.jatoba.example\nDB_USER=svc_backup\nDB_PASS=Ipe-Amarelo-2019\n" | sudo tee /srv/portal/old-backup/db-credentials.txt >/dev/null'
on web 'sudo systemd-run -q --unit canary bash /home/ana/canary.sh'

block token-touch
on web 'sleep 1; sudo cat /srv/portal/old-backup/db-credentials.txt | head -1'
on web 'sleep 1; sudo journalctl -t canary -o short-iso --no-pager'

block account
on desk 'ssh -o BatchMode=yes svc_backup@web true'
on web 'sudo journalctl -u ssh -o short-iso --no-pager | grep svc_backup'
