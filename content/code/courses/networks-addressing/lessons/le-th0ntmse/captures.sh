#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "vlans" scenario: two switches, sw1 and sw2, joined by
# one cable on port p24 of each, with VLAN filtering on and every port in the
# default VLAN 1. pc1 and pc2 hang off sw1; pc3, pc4 and pc5 off sw2. The
# switches are the Linux kernel's bridge, configured with the `bridge vlan`
# command; a commercial switch says the same things in its own words.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up vlans`; the neighbour tables of the PCs emptied before
# a block that watches ARP; and the same port configuration typed on sw2 as
# on sw1 where the lesson says so, which is shown for sw1 only.
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
flushall() { for h in pc1 pc2 pc3 pc4 pc5; do quiet $h 'ip neigh flush all'; done; }

lab up vlans

block one-lan
root sw1 'bridge vlan show'
flushall
bgon root pc2 'timeout 6 tcpdump -n -e -i eth0 arp'
on pc1 'ping -c 1 -q 10.20.10.23'
fgon

block access
root sw1 'bridge vlan add dev p1 vid 10 pvid untagged'
root sw1 'bridge vlan add dev p2 vid 20 pvid untagged'
root sw1 'bridge vlan del dev p1 vid 1'
root sw1 'bridge vlan del dev p2 vid 1'
root sw2 'for p in p1; do bridge vlan add dev $p vid 10 pvid untagged; bridge vlan del dev $p vid 1; done'
root sw2 'for p in p2 p3; do bridge vlan add dev $p vid 20 pvid untagged; bridge vlan del dev $p vid 1; done'
root sw1 'bridge vlan show'
on pc1 'ping -c 2 -W 1 -q 10.20.10.23'

block trunk
root sw1 'bridge vlan add dev p24 vid 10'
root sw1 'bridge vlan add dev p24 vid 20'
quiet sw2 'bridge vlan add dev p24 vid 10; bridge vlan add dev p24 vid 20'
root sw1 'bridge vlan show dev p24'
on pc1 'ping -c 2 -q 10.20.10.23'
on pc2 'ping -c 2 -q 10.20.20.24'

block tag
flushall
bgon root sw1 'timeout 8 tcpdump -n -e -i p24 -c 4 icmp'
on pc1 'ping -c 1 -q 10.20.10.23'
on pc2 'ping -c 1 -q 10.20.20.24'
fgon
bgon root pc3 'timeout 6 tcpdump -n -e -i eth0 -c 2 icmp'
on pc1 'ping -c 1 -q 10.20.10.23'
fgon

block isolation
flushall
on pc1 'ping -c 2 -W 1 -q 10.20.10.25'
on pc1 'ip neigh'
bgon root pc5 'timeout 6 tcpdump -n -e -i eth0 arp'
on pc1 'ping -c 1 -W 1 -q 10.20.10.25'
fgon

block native-mismatch
root sw1 'bridge vlan add dev p24 vid 10 pvid untagged'
root sw2 'bridge vlan add dev p24 vid 20 pvid untagged'
root sw1 'bridge vlan show dev p24'
root sw2 'bridge vlan show dev p24'
flushall
on pc1 'ping -c 2 -q 10.20.10.25'
on pc1 'ping -c 2 -W 1 -q 10.20.10.23'

block native-fix
root sw1 'bridge vlan add dev p24 vid 10 && bridge vlan add dev p24 vid 999 pvid untagged'
root sw2 'bridge vlan add dev p24 vid 20 && bridge vlan add dev p24 vid 999 pvid untagged'
root sw1 'bridge vlan show dev p24'
flushall
on pc1 'ping -c 2 -q 10.20.10.23'
on pc1 'ping -c 2 -W 1 -q 10.20.10.25'
