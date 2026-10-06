#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# Everything happens on the office laptop, as ana: ana@laptop is her prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, whose build_logins writes logins.csv and
# red-team-sources.txt into ana's home folder; lab.sh's comment above that
# function says exactly what the week contains and why. detect.py, beside this
# script, is copied into ana's home folder before the first command; the lesson
# prints it as a schooling-example, cut at its blank lines into parts with
# notes, and every part is that file's text unchanged. Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
HERE=$(cd "$(dirname "$0")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab reset
install -o ana -g ana -m 644 "$HERE/detect.py" /lab/laptop/home/ana/detect.py

block data
on laptop 'wc -l logins.csv'
on laptop 'grep -m 3 ",fail$" logins.csv'
on laptop 'cat red-team-sources.txt'

block five
on laptop 'python3 detect.py 5'

block three
on laptop 'python3 detect.py 3'

block ignored
on laptop 'python3 detect.py 3 svc-backup'
