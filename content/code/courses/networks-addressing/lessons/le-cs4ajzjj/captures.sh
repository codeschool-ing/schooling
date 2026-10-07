#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "office" scenario: pc1, pc2, pc3 and srv on the switch
# sw1 (ports p1, p2, p3 and p4), and the router r1 on port p8, with the
# provider isp on its other side. The switch is the Linux kernel's bridge.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up office`; the switch's MAC table and every neighbour
# table emptied at the start of the first two blocks, so each begins with
# nothing learnt; and pc3's learnt address removed from the table once p3
# is locked, so the lock meets a port with nothing learnt on it. Everything
# else is typed, including the made-up neighbour on pc1 that the flooding
# block needs: a MAC address no card in the lab has.
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
reset_tables() { for h in pc1 pc2 pc3 srv r1; do quiet $h 'ip neigh flush all'; done; quiet sw1 'bridge fdb flush dev br0 dynamic'; }

lab up office

block learning
reset_tables
root sw1 'bridge fdb show br br0 dynamic'
on pc1 'ping -c 1 -q 10.20.10.10'
root sw1 'bridge fdb show br br0 dynamic'
root sw1 'bridge -s fdb show br br0 dynamic'
root sw1 'ip -d link show br0 | grep -o "ageing_time [0-9]*"'
on pc1 'ip link show eth0 | grep ether'
on pc3 'ip link show eth0 | grep ether'

block flooding
reset_tables
on pc1 'ping -c 1 -q 10.20.10.10'
bgon root pc3 'timeout 8 tcpdump -n -e -i eth0 icmp'
on pc1 'ping -c 2 -q 10.20.10.10'
root pc1 'ip neigh add 10.20.10.99 lladdr 02:00:00:00:00:99 dev eth0'
on pc1 'ping -c 2 -W 1 -q 10.20.10.99'
fgon
root sw1 'bridge fdb show br br0 dynamic | grep -c .'
root sw1 'bridge fdb show br br0 | grep 02:00:00:00:00:99'

block broadcast-domain
quiet pc1 'ip neigh flush all'
bgon root pc3 'timeout 6 tcpdump -n -e -i eth0 arp'
on pc1 'ping -c 1 -q 10.20.10.22'
fgon
bgon root isp 'timeout 6 tcpdump -n -i eth0 arp'
quiet pc1 'ip neigh flush all'
on pc1 'ping -c 1 -q 10.20.10.22'
fgon

block duplex
on pc1 'sudo ethtool eth0 | grep -E "Speed|Duplex"'
on pc1 'ip -s link show eth0 | tail -2'

block locked-port
root sw1 'bridge link set dev p3 locked on learning off'
quiet sw1 'bridge fdb del 02:d9:6b:02:17:20 dev p3 master'; quiet pc3 'ip neigh flush all'; quiet srv 'ip neigh flush all'
root sw1 'bridge fdb show br br0 dynamic | grep "dev p3 "'
on pc3 'ping -c 2 -W 1 -q 10.20.10.10'
root sw1 'bridge fdb add 02:d9:6b:02:17:20 dev p3 master static'
on pc3 'ping -c 2 -W 1 -q 10.20.10.10'
root pc3 'ip link set eth0 address 02:00:00:00:00:66'
on pc3 'ping -c 2 -W 1 -q 10.20.10.10'
root sw1 'bridge -d link show dev p3 | grep -oE "(learning|locked) [a-z]*"'
