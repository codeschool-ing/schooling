#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. ana@laptop
# ran on the office laptop; root@www is the administrator on the server that
# runs the portal. bruno's requests are sent from the same laptop with his
# password, the way he would from his own desk.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, including the portal's two accounts, ana
# (staff) and bruno (staff and hr), whose passwords are the lab's. The code
# quoted in the lesson's schooling-example is the payslip branch of
# /srv/portal/portal.py as lab.sh writes it, printed by the last block of this
# script with sed; the lesson cuts it into parts and takes eight spaces of
# indentation off every line. Every line after a prompt is what the command
# printed.
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

block anon
on laptop 'curl -si http://www.example.com/payslips/ana'

block wrong
on laptop 'curl -s -o /dev/null -w "%{http_code}\n" -u ana:wrong-guess http://www.example.com/payslips/ana'

block right
on laptop 'curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana'
on laptop 'curl -si -u ana:lab-ana-pass http://www.example.com/payslips/bruno'

block hr
on laptop 'curl -s -u bruno:lab-bruno-pass http://www.example.com/payslips/ana'

block exists
on laptop 'curl -s -w "%{http_code}\n" -u ana:lab-ana-pass http://www.example.com/payslips/carla'
on laptop 'curl -s -w "%{http_code}\n" -u bruno:lab-bruno-pass http://www.example.com/payslips/carla'

block log
root www 'cat /var/log/lab/portal.log'

block code
root www "sed -n '/startswith..\\/payslips/,/September/p' /srv/portal/portal.py"
