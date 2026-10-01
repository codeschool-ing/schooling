#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of networks-addressing, as a script
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
# The lab is lab.sh's "chain" scenario: r1, r2 and r3 in a line, pc1 behind r1
# and pc3 behind r3, and a spare cable from r1 straight to r3. The routers
# start with only their connected routes, and every static route in the
# lesson is typed.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up chain`; and the cable from r1 to r2 pulled in the
# floating-route block, which the script does by setting r2's end of it down,
# so r1 sees its signal go as it would with a real cable, and r2 loses that
# link too.
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

lab up chain

block start
root r1 'ip route'
on pc1 'ping -c 1 -W 1 10.20.3.10'

block one-way
root r1 'ip route add 10.20.3.0/24 via 10.20.12.2'
root r2 'ip route add 10.20.3.0/24 via 10.20.23.2'
bgon root pc3 'timeout 6 tcpdump -n -i eth0 -c 3 icmp'
on pc1 'ping -c 1 -W 2 10.20.3.10'
fgon

block return-path
root r3 'ip route add 10.20.1.0/24 via 10.20.23.1'
root r2 'ip route add 10.20.1.0/24 via 10.20.12.1'
on pc1 'ping -c 2 10.20.3.10'
on pc1 'traceroute -n 10.20.3.10'
root r2 'ip route'

block floating
root r1 'ip route add 10.20.3.0/24 via 10.20.13.2 metric 200'
root r3 'ip route add 10.20.1.0/24 via 10.20.13.1 metric 200'
root r1 'ip route show 10.20.3.0/24'
quiet r2 'ip link set eth1 down'
root r1 'ip route show 10.20.3.0/24'
root r1 'ip route get 10.20.3.10'
root r3 'ip route get 10.20.1.10'
on pc1 'ping -c 2 -W 1 10.20.3.10'
on pc3 'traceroute -n 10.20.1.10'

block stub
root r3 'ip route del 10.20.1.0/24 via 10.20.23.1'
root r3 'ip route del 10.20.1.0/24 via 10.20.13.1 metric 200'
root r3 'ip route add default via 10.20.13.1'
root r3 'ip route'
on pc1 'ping -c 2 -W 1 10.20.3.10'
quiet r2 'ip link set eth1 up'
