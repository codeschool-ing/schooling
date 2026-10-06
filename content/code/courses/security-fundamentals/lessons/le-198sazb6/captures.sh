#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh, and the
# exercise is against the shop's own portal, agreed in advance. ana@outside is
# ana playing the red side from a machine on the internet; root@www is the
# administrator reading the portal's log, playing the blue side.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; one ordinary request from the office laptop
# before the exercise, so the log holds normal traffic as well. The six
# passwords are wrong on purpose and are the lab's. Every line after a prompt
# is what the command printed.
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
lab exec laptop ana 'curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana >/dev/null'

block red
on outside 'for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-$i http://www.example.com/payslips/ana; done'

block blue
root www "grep -c ' 401 ' /var/log/lab/portal.log"
root www "grep ' 401 ' /var/log/lab/portal.log | cut -d' ' -f1 | sort | uniq -c"

block gap
root www 'head -3 /var/log/lab/portal.log'
