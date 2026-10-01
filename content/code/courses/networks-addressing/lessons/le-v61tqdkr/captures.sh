#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks-addressing, as a script
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
# The lab is lab.sh's "office" scenario: four PCs on one switch, a router, a
# provider and a web service behind it. A line that starts with ana@pc1 ran on
# the machine called pc1; root@sw1 is the switch, at a root prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh up office`; every neighbour table and the switch's
# MAC table emptied before the first block, and the switch's MAC table
# emptied again at the start of the bridge block; and, for the last block, pc2's
# default route replaced by one pointing at 10.20.10.254, an address nobody
# has, which is the mistake the block is about.
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

lab up office
for h in pc1 pc2 pc3 srv r1; do quiet $h 'ip neigh flush all'; done

block nic
on pc1 'ip link show eth0'
on pc1 'ethtool -i eth0'
on pc1 'ip -s link show eth0'
on pc1 'ping -c 5 -q 10.20.10.10'
on pc1 'ip -s link show eth0'

block bridge
root sw1 'bridge link show'
quiet sw1 'bridge fdb flush dev br0 dynamic'
root sw1 'bridge fdb show br br0 dynamic'
on pc1 'ping -c 1 -q 10.20.10.10'
on pc2 'ping -c 1 -q 10.20.10.10'
root sw1 'bridge fdb show br br0 dynamic'
root sw1 'ip -d link show br0 | grep -o "ageing_time [0-9]*"'

block gateway
on pc1 'ip route'
on pc1 'ip neigh'
bgon root pc1 'timeout 5 tcpdump -n -e -c 2 -i eth0 icmp'
on pc1 'ping -c 1 192.0.2.80'
fgon
on pc1 'ip neigh'
root r1 'ip -br link show eth0'

block wrong-gateway
quiet pc2 'ip route replace default via 10.20.10.254'
on pc2 'ip route'
on pc2 'ping -c 1 10.20.10.10'
on pc2 'ping -c 2 192.0.2.80'
on pc2 'ip neigh'
