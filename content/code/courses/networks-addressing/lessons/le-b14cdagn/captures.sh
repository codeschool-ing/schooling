#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana       # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh    # the lab, beside course.json
#   sudo bash captures.sh
#
# The calculator is ipcalc 0.51, whose -s option splits a block into subnets
# of the sizes asked for. The lab is lab.sh's "plan" scenario, which is the
# plan this lesson draws, built: sales1, eng1 and ops1 on three subnets of
# 10.20.32.0/24 behind r1, a /30 from r1 to r2, and hq1 behind r2.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up plan`. The overlapping address in the last block is
# typed in the lesson.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
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

lab up plan

block fixed
on hq1 'ipcalc -b 10.20.32.0/26'

block split
on hq1 'ipcalc 10.20.32.0/24 -s 100 50 20 2'

block applied
root r1 'ip -br addr'
root r1 'ip route'
root r2 'ip route'
on hq1 'ping -c 1 -q 10.20.32.10'
on hq1 'ping -c 1 -q 10.20.32.140'
on hq1 'ping -c 1 -q 10.20.32.200'
on hq1 'traceroute -n 10.20.32.200'

block summary
root r2 'ip route get 10.20.32.140'
root r2 'ip route get 10.20.32.250'
on hq1 'ping -c 1 -W 1 10.20.32.250'
on hq1 'traceroute -n -m 6 10.20.32.250'
root r1 'ip route add unreachable 10.20.32.0/24'
on hq1 'ping -c 1 -W 1 10.20.32.250'
on hq1 'ping -c 1 -q 10.20.32.140'

block overlap
root r1 'ip addr add 10.20.32.130/25 dev eth3'
root r1 'ip route'
root r1 'ip route get 10.20.32.140'
root r1 'ip route get 10.20.32.180'
on hq1 'ping -c 1 -W 1 10.20.32.140'
on hq1 'ipcalc -b 10.20.32.130/25'
