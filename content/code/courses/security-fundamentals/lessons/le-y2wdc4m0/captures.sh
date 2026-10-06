#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. ana@laptop
# ran on the office laptop, ana@outside on the machine on the internet, and
# root@www is the administrator on the server that runs the portal.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, which starts the portal with
# /srv/portal/mode saying perimeter; fw filters nothing, as lab.sh leaves it,
# so that what the lesson compares is the portal's policy and nothing else.
# The portal reads the mode file on every request, which is why writing it
# takes effect without a restart. Every line after a prompt is what the
# command printed.
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

block perimeter
root www 'cat /srv/portal/mode'
on laptop 'curl -s http://www.example.com/handbook'
on outside 'curl -s http://www.example.com/handbook'
on outside 'curl -s -u ana:lab-ana-pass http://www.example.com/handbook'

block switch
root www 'echo zerotrust > /srv/portal/mode'

block zerotrust
on laptop 'curl -s http://www.example.com/handbook'
on laptop 'curl -s -u ana:lab-ana-pass http://www.example.com/handbook'
on outside 'curl -s -u ana:lab-ana-pass http://www.example.com/handbook'

block log
root www 'cat /var/log/lab/portal.log'
