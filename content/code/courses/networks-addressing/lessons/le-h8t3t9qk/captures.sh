#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of networks-addressing, as a script
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
# Three scenarios of lab.sh, one after the other: "office" is a star, four PCs
# and a router on one switch; "ring" is four routers in a ring, with a PC
# behind r1 and another behind r2; "mesh" is the same four routers with a
# cable between every pair. The routers find their paths with OSPF, which
# lesson 16 explains; here it is only what makes a ring or a mesh use a second
# path by itself.
#
# What is STAGED rather than typed, and not shown in the lesson: each scenario,
# built by `lab.sh up`. A cable is "cut" by setting one end of it down, which
# the other end sees as a lost signal, exactly as with a pulled cable.
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

block star-one-cable
root sw1 'ip link set p3 down'
on pc3 'ping -c 2 -W 1 10.20.10.10'
on pc1 'ping -c 2 -W 1 10.20.10.10'
quiet sw1 'ip link set p3 up'

block star-centre
root sw1 'ip link set br0 down'
on pc1 'ping -c 2 -W 1 10.20.10.10'
on pc2 'ping -c 2 -W 1 10.20.10.10'
quiet sw1 'ip link set br0 up'

lab up ring

block ring
root r1 'ip -br addr'
on pc1 'traceroute -n 10.20.2.10'
bgon ana pc1 'ping -c 30 -i 0.5 -q 10.20.2.10'
root r1 'ip link set eth1 down'
fgon
on pc1 'traceroute -n 10.20.2.10'
root r1 'ip route show 10.20.2.0/24'

lab up mesh

block mesh
root r1 'ip -br addr'
on pc1 'traceroute -n 10.20.2.10'
bgon ana pc1 'ping -c 30 -i 0.5 -q 10.20.2.10'
root r1 'ip link set eth1 down'
fgon
on pc1 'traceroute -n 10.20.2.10'
