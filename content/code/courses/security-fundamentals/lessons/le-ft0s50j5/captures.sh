#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh. A line that
# starts with ana@laptop ran on the office laptop as ana; root@www is the
# administrator on the server that runs the shop.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; prices.csv, written into ana's home folder by
# this script before the first command. Every line after a prompt is what the
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
lab exec laptop ana 'printf "isbn,title,price_cents\n9788535914849,Dom Casmurro,4590\n9788525432186,Vidas Secas,3990\n9788520932964,Grande Sertao: Veredas,8990\n" > prices.csv'

block hash
on laptop 'cat prices.csv'
on laptop 'sha256sum prices.csv > prices.sha256'
on laptop 'cat prices.sha256'
on laptop 'sha256sum -c prices.sha256'

block tamper
on laptop "sed -i 's/,4590/,459/' prices.csv"
on laptop 'cat prices.csv'
on laptop 'sha256sum -c prices.sha256'
on laptop 'sha256sum prices.csv'

block down
on laptop 'curl -s http://www.example.com/'
root www 'kill $(cat /srv/portal/portal.pid)'
on laptop 'curl -s http://www.example.com/; echo "exit $?"'
root www 'portal-restart'
on laptop 'curl -s http://www.example.com/'
