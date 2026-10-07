#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "igp" scenario: four routers in a ring (r1, r2, r3, r4),
# pc1 behind r1 and pc2 behind r2. FRR 8.4 runs on every router
# with nothing configured, and everything the lesson shows configured is
# typed into vtysh at the router's prompt: the same configuration on all four
# routers, printed once for r1 and run silently on the other three.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up igp`; the identical configuration typed on r2, r3 and
# r4; the waits for each protocol to finish converging before the tables are
# read; and, in the convergence block, a failure that leaves the signal up:
# r1's cable to r4 stops carrying anything in either direction, as when a
# media converter or a switch between them dies, which the script does with
# an nftables rule on r1 that drops every frame on that interface.
#
# EIGRP is run with FRR's eigrpd only to show the tables it keeps.
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
# conf_all 'vtysh args': typed on r1, and the same run quietly on r2, r3, r4
conf_all() { root r1 "$1"; for r in r2 r3 r4; do quiet $r "$1"; done; }
waitfor() { local h=$1 c=$2; for _ in $(seq 120); do lab exec $h root "$c" >/dev/null 2>&1 && return; sleep 1; done; echo "(waited 120 s for: $c)"; }

lab up igp

block no-protocol
root r1 'ip route'
on pc1 'ping -c 1 -W 1 10.20.2.10'

block rip
conf_all 'vtysh -c "configure terminal" -c "router rip" -c "version 2" -c "network 10.20.0.0/16"'
waitfor r1 'ip route | grep -q "10.20.0.8/30"'
waitfor r3 'ip route | grep -q "10.20.1.0/24"'
root r1 'vtysh -c "show ip rip"'
root r1 'ip route'
on pc1 'traceroute -n 10.20.2.10'

block rip-off
conf_all 'vtysh -c "configure terminal" -c "no router rip"'
sleep 3

block ospf
conf_all 'vtysh -c "configure terminal" -c "interface eth1" -c "ip ospf network point-to-point" -c "ip ospf cost 100" -c "interface eth2" -c "ip ospf network point-to-point" -c "interface eth3" -c "ip ospf network point-to-point" -c "interface eth4" -c "ip ospf network point-to-point" -c "router ospf" -c "network 10.20.0.0/16 area 0"'
waitfor r1 'vtysh -c "show ip ospf neighbor" | grep -c Full | grep -q 2'
waitfor r3 'ip route | grep -q "10.20.1.0/24 .*proto ospf"'
waitfor pc1 'ping -c1 -W1 10.20.2.10'
root r1 'vtysh -c "show ip ospf neighbor"'
root r1 'vtysh -c "show ip ospf interface eth1" | grep -E "Cost|Timer|Network Type"'
root r1 'vtysh -c "show ip ospf interface eth4" | grep -E "Cost"'
root r1 'vtysh -c "show ip route ospf"'
on pc1 'traceroute -n 10.20.2.10'

block database
root r1 'vtysh -c "show ip ospf database"'
root r1 'vtysh -c "show ip ospf route"'

block convergence
bgon ana pc1 'ping -c 70 -i 1 -q 10.20.2.10'
quiet r1 'nft add table netdev cut; nft add chain netdev cut in "{ type filter hook ingress device eth4 priority 0; policy drop; }"; nft add table inet cutout; nft add chain inet cutout out "{ type filter hook output priority 0; }"; nft add rule inet cutout out oifname eth4 drop; nft add chain inet cutout fwd "{ type filter hook forward priority 0; }"; nft add rule inet cutout fwd oifname eth4 drop'
sleep 20
root r1 'vtysh -c "show ip ospf neighbor"'
fgon
root r1 'vtysh -c "show ip ospf neighbor"'
on pc1 'traceroute -n 10.20.2.10'
quiet r1 'nft delete table netdev cut; nft delete table inet cutout'

block eigrp
conf_all 'vtysh -c "configure terminal" -c "router eigrp 64500" -c "network 10.20.0.0/16"'
waitfor r1 'vtysh -c "show ip eigrp neighbor" | grep -q 10.20.0.2'
sleep 10
root r1 'vtysh -c "show ip eigrp neighbor"'
root r1 'vtysh -c "show ip eigrp topology"'
