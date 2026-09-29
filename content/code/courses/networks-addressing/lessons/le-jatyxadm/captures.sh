#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of networks-addressing, as a script
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
# The lab is lab.sh's "campus" scenario: two core routers (c1, c2), two
# distribution routers (d1, d2) each cabled to both cores, an access switch
# under each distribution router (a1, a2) and a PC on each access switch. The
# routers use OSPF (lesson 16) and every device runs an LLDP agent.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up campus`, and a wait of forty seconds after it, so every
# LLDP agent has announced itself to its neighbours at least once. The lab is
# built a second time before the single-point-of-failure block, so it starts
# from every cable working. A cable is cut by setting one end of it down; a
# router "fails" by having every one of its interfaces set down.
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

lab up campus
sleep 40

block tiers
root c1 'vtysh -c "show ip ospf neighbor"'
root d1 'vtysh -c "show ip ospf neighbor"'
on pc1 'traceroute -n 10.20.12.22'

block scale
root c1 'ip route'
root c1 'ip route | wc -l'

block documentation
root d1 'lldpcli show neighbors summary'
root a1 'lldpcli show neighbors summary'
root d1 'ip -br addr'

block redundancy
root d1 'ip route show 10.20.12.0/24'
bgon ana pc1 'ping -c 20 -i 0.5 -q 10.20.12.22'
root d1 'ip link set eth2 down'
fgon
root d1 'ip route show 10.20.12.0/24'
on pc1 'traceroute -n 10.20.12.22'

lab up campus

block spof
root d1 'for i in eth0 eth1 eth2; do ip link set $i down; done'
on pc1 'ping -c 3 -W 1 10.20.11.1'
on pc1 'ping -c 3 -W 1 10.20.12.22'
