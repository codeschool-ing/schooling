#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "stp" scenario: three switches (sw1, sw2, sw3) cabled
# in a triangle, a PC on port p10 of each, and spanning tree off. The
# switches are the Linux kernel's bridge, whose spanning tree is the original
# IEEE 802.1D protocol with its default timers: a hello every 2 s, a max age
# of 20 s and a forward delay of 15 s.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up stp` with the cable from sw3 to sw1 unplugged; that
# cable plugged in and, three seconds later, unplugged again in the loop
# block, and plugged in for good once spanning tree is on; the wait for
# spanning tree to settle after it is switched on; and, in the failover
# block, the cable from sw1 to sw2 pulled. A cable is plugged and pulled by
# setting one end of it up or down, which the other end sees as the signal
# coming and going.
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
waitfor() { local h=$1 c=$2; for _ in $(seq 120); do lab exec $h root "$c" >/dev/null 2>&1 && return; sleep 1; done; echo "(waited 120 s for: $c)"; }

lab up stp

block loop
root sw1 'bridge link show'
root sw1 'ip -s link show p2 | sed -n "3,6p"'
quiet sw3 'ip link set p1 up'
sleep 3
quiet sw3 'ip link set p1 down'
root sw1 'ip -s link show p2 | sed -n "3,6p"'

block enable
root sw1 'ip link set br0 type bridge stp_state 1'
root sw2 'ip link set br0 type bridge stp_state 1'
root sw3 'ip link set br0 type bridge stp_state 1'
quiet sw3 'ip link set p1 up'
root sw1 'bridge link show'
sleep 40
root sw1 'bridge link show'
root sw2 'bridge link show'
root sw3 'bridge link show'
on pc1 'ping -c 2 -q 10.20.10.23'

block election
root sw1 'cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost'
root sw2 'cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost'
root sw3 'cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost'
root sw3 'ip -d link show p1 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"'
root sw3 'ip -d link show p2 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"'

block priority
root sw3 'ip link set br0 type bridge priority 4096'
sleep 40
root sw3 'cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port'
root sw1 'bridge link show'
root sw2 'bridge link show'

block failover
quiet sw3 'ip link set br0 type bridge priority 32768'
sleep 60
root sw2 'bridge link show'
bgon ana pc2 'ping -c 60 -i 1 -q 10.20.10.21'
quiet sw1 'ip link set p2 down'
root sw2 'for i in 1 2 3 4 5 6 7; do date +%T; bridge link show dev p3 | grep -o "state [a-z]*"; sleep 6; done'
fgon

block guard
root sw1 'bridge link set dev p10 guard on'
root sw1 'bridge link show dev p10'
root pc1 'ip link add br9 type bridge stp_state 1 && ip link set eth0 master br9 && ip link set br9 up'
sleep 6
root sw1 'bridge link show dev p10'
