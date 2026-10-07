#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "paths" scenario: pc1 behind the router r1, which is
# cabled to two routers, ra and rb, that both sit on the network 10.30.0.0/16
# where far1 (10.30.5.10) and far2 (10.30.7.10) live. r1 starts with only its
# connected routes; every other route in the lesson is typed. FRR runs on r1
# with an empty configuration.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up paths`, including the return routes on ra and rb
# towards the office; and, in the metrics block, the cable from r1 to ra
# pulled and plugged back, which the script does by setting ra's end of it
# down and up, so r1 sees the signal go exactly as with a real cable.
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

lab up paths

block connected
root r1 'ip route'
on pc1 'ping -c 1 -W 1 10.30.5.10'

block default
root r1 'ip route add default via 10.20.1.2'
root r1 'ip route'
on pc1 'traceroute -n 10.30.5.10'

block longest-prefix
root r1 'ip route add 10.30.0.0/16 via 10.20.1.2'
root r1 'ip route add 10.30.5.0/24 via 10.20.2.2'
root r1 'ip route'
root r1 'ip route get 10.30.5.10'
root r1 'ip route get 10.30.7.10'
root r1 'ip route get 192.0.2.1'
on pc1 'traceroute -n 10.30.5.10'
on pc1 'traceroute -n 10.30.7.10'

block metrics
root r1 'ip route del default via 10.20.1.2'
root r1 'ip route add default via 10.20.1.2 metric 100'
root r1 'ip route add default via 10.20.2.2 metric 200'
root r1 'ip route show default'
root r1 'ip route get 198.51.100.7'
quiet ra 'ip link set eth0 down'
root r1 'ip -br link show eth1'
root r1 'ip route show default'
root r1 'ip route get 198.51.100.7'
quiet ra 'ip link set eth0 up'
sleep 2

block distance
root r1 'vtysh -c "show ip route"'
root r1 'vtysh -c "configure terminal" -c "ip route 10.40.0.0/16 10.20.1.2" -c "ip route 10.40.0.0/16 10.20.2.2 200"'
root r1 'vtysh -c "show ip route 10.40.0.0/16"'
root r1 'ip route show 10.40.0.0/16'
