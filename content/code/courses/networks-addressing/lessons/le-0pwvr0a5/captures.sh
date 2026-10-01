#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of networks-addressing, as a script
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
# The calculators are ipcalc 0.51 and sipcalc 1.1.6, as Ubuntu 24.04 packages
# them. The lab is lab.sh's "plan" scenario: 10.20.32.0/24 cut into three
# LANs of different sizes behind the router r1 (sales1 in 10.20.32.0/25, eng1
# in 10.20.32.128/26, ops1 in 10.20.32.192/27), and hq1 behind r2 upstream.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up plan`. The wrong mask on sales1 is typed in the lesson.
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

block mask
on sales1 'ip -br addr show eth0'
on sales1 'ipcalc 10.20.32.10/25'

block prefixes
on sales1 'ipcalc -b 10.20.32.140/26'
on sales1 'ipcalc -b 10.20.32.200/27'
on sales1 'ipcalc -b 10.20.32.224/30'
on sales1 'ipcalc -b 10.20.32.224/31'
on sales1 'ipcalc -b 10.20.32.10/32'

block sipcalc
on sales1 'sipcalc 172.16.45.77/20'

block routes
on sales1 'ip route'
on sales1 'ip route get 10.20.32.100'
on sales1 'ip route get 10.20.32.140'

block wrong-mask
root sales1 'ip addr del 10.20.32.10/25 dev eth0 && ip addr add 10.20.32.10/24 dev eth0 && ip route add default via 10.20.32.1'
on sales1 'ip route'
on sales1 'ping -c 2 -W 1 10.20.99.10'
on sales1 'ping -c 2 -W 1 10.20.32.140'
on sales1 'ip neigh'
on sales1 'ip route get 10.20.32.140'
