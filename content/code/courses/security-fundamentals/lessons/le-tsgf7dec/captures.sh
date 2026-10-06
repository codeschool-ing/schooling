#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. ana@outside
# is ana testing from a machine on the internet, the way a stranger would
# reach the shop; root@www is the administrator on the server that runs the
# portal.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset. ana's password is the lab's, lab-ana-pass,
# and the lesson treats it as leaked on purpose. Every line after a prompt is
# what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab reset

block nologin
on outside 'curl -s http://www.example.com/payslips/bruno'

block leaked
on outside 'curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana'
on outside 'curl -s -u ana:lab-ana-pass http://www.example.com/payslips/bruno'

block files
root www 'ls -l /srv/hr/salaries.csv'
root www 'setpriv --reuid=shop --regid=shop --clear-groups cat /srv/hr/salaries.csv'

block log
root www 'cat /var/log/lab/portal.log'
