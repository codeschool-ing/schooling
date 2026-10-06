#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. All of it
# happens on www, the server that runs the portal: root@www is the
# administrator, ana@www and bruno@www are those two people logged in there.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, which creates the accounts, the hr group, the
# salaries file and ana's sudo rule (/etc/sudoers.d/ana on www, shown in the
# lesson through sudo -l); two requests to the portal from the office laptop
# before the first command, so that its log has something in it. Every line
# after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
lab() { bash "$LAB_SH" "$@"; }
as() {    # as USER HOST 'command': somebody at their prompt on one machine of the lab
  local u=$1 h=$2; shift 2
  printf '%s@%s:~$ %s\n' "$u" "$h" "$*"
  lab exec "$h" "$u" "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab reset
lab exec laptop ana 'curl -s http://www.example.com/ >/dev/null; curl -s http://www.example.com/handbook >/dev/null'

block who
root www 'id shop'
root www 'ps -o user,args -p $(cat /srv/portal/portal.pid)'
root www "getpcaps \$(cat /srv/portal/portal.pid) | cut -d' ' -f2"

block files
root www 'ls -l /srv/hr/salaries.csv /srv/portal/users'
as bruno www 'id'
as bruno www 'cat /srv/hr/salaries.csv'
as ana www 'cat /srv/hr/salaries.csv'

block sudo
as ana www 'sudo -l'
as ana www 'sudo tail /var/log/lab/portal.log'
as ana www 'sudo -l tail /var/log/lab/portal.log; echo "exit $?"'
as ana www 'sudo -l cat /srv/hr/salaries.csv; echo "exit $?"'
