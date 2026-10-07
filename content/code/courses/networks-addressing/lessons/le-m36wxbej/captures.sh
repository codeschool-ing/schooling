#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "office" scenario: four PCs and a server on one switch,
# the router r1, which does NAT for the office, and the provider isp outside.
# srv runs a web server on port 80 from the moment the lab is built.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up office`; and the connections that ss lists, which are
# held open in the background by `sleep N | timeout M nc HOST PORT`, one per client,
# because a web page's connection closes in milliseconds and would never be
# caught by a listing. The listeners on pc1 and pc2 are started the same way.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-$(cd "$(dirname "$0")/../.." && pwd)/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() { local h=$1; shift; printf 'ana@%s:~$ %s\n' "$h" "$*"; lab exec "$h" ana "$*" 2>&1 || true; }
# root HOST 'command': the same at a root prompt, on a device being configured.
root() { local h=$1; shift; printf 'root@%s:~# %s\n' "$h" "$*"; lab exec "$h" root "$*" 2>&1 || true; }
# quiet HOST 'command': the lab's own housekeeping, run as root and not shown.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {  # bgon USER HOST 'command'
  local p='$'; [ "$1" = root ] && p='#'
  printf '%s@%s:~%s %s\n' "$1" "$2" "$p" "$3" > /tmp/bg.out
  lab exec "$2" "$1" "$3" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 2
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab up office

block server
root srv 'ss -tln'
on pc1 'curl -s http://srv/'

block many-clients
for h in pc1 pc2 pc3; do lab exec $h ana 'sleep 4 | timeout 6 nc -N srv 80' >/dev/null 2>&1 & done
sleep 2
root srv 'ss -tn'
wait

block peers
lab exec pc1 ana 'timeout 8 nc -l 8000 </dev/null' >/dev/null 2>&1 &
lab exec pc2 ana 'timeout 8 nc -l 8000 </dev/null' >/dev/null 2>&1 &
sleep 1
lab exec pc1 ana 'sleep 5 | timeout 6 nc pc2 8000' >/dev/null 2>&1 &
lab exec pc2 ana 'sleep 5 | timeout 6 nc pc1 8000' >/dev/null 2>&1 &
sleep 2
on pc1 'ss -tn'
on pc2 'ss -tn'
wait

block nat
on pc1 'curl -s -m 3 http://192.0.2.80/'
root isp 'nc -z -v -w 3 203.0.113.2 8000'
root r1 'conntrack -L -p tcp 2>/dev/null | head -3'
