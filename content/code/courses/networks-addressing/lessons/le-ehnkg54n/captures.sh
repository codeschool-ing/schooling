#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of networks-addressing, as a script
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
# The lab is lab.sh's "office" scenario: pc1, pc2, pc3 and srv on one switch
# in 10.20.10.0/24, behind the router r1. The calculator is ipcalc 0.51, the
# version Ubuntu 24.04 packages.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up office`. Everything else, including the setting that
# makes pc2 and pc3 answer a broadcast ping, is typed at a prompt in the
# lesson.
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

block binary
on pc1 'ipcalc 10.20.10.21/24'

block classes
on pc1 'ipcalc -b 10.1.2.3'
on pc1 'ipcalc -b 172.16.5.4'
on pc1 'ipcalc -b 192.168.1.1'
on pc1 'ipcalc -b 224.0.0.5'

block private-public
on pc1 'ip -br addr show eth0'
root r1 'ip -br addr'
on pc1 'ipcalc -b 203.0.113.2'
on pc1 'ipcalc -b 100.64.1.1'

block loopback
on pc1 'ip addr show lo'
on pc1 'ping -c 1 127.0.0.1'
on pc1 'ping -c 1 127.45.6.7'
on pc1 'ipcalc -b 127.0.0.1'

block broadcast
on pc1 'ip addr show eth0 | grep "inet "'
on pc1 'ping -b -c 2 10.20.10.255'
on pc2 'sysctl net.ipv4.icmp_echo_ignore_broadcasts'
root pc2 'sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0'
root pc3 'sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0'
on pc1 'ping -b -c 2 10.20.10.255'

block special
on pc1 'ipcalc -b 169.254.10.10'
on pc1 'ip route get 8.8.8.8'
on pc1 'ss -tln'
root srv 'ss -tln'
