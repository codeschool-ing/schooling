#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "bgp" scenario: a company with the block 203.0.113.0/24
# and the autonomous system 64500, whose router edge is cabled to two
# providers, ispa (AS 64501) and ispb (AS 64502), which also peer with each
# other. Each provider has a customer network of its own with one host on it
# (a1 and b1). The addresses and AS numbers are the ones reserved for
# documentation. The providers' configuration is in lab.sh, and it already
# accepts nothing from the company but 203.0.113.0/24; everything on edge is
# typed in the lesson, into FRR 8.4's vtysh.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up bgp`, and the waits for each session to come up and for
# each change of policy to reach the other routers before the tables are
# read.
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

lab up bgp
waitfor ispa 'vtysh -c "show bgp summary" | grep -q "^192.0.2.10 .* 1 "'

block providers
root ispa 'vtysh -c "show ip bgp"'
on a1 'ping -c 1 -W 1 203.0.113.10'

block session
root edge 'vtysh -c "configure terminal" -c "router bgp 64500" -c "bgp router-id 192.0.2.1" -c "neighbor 192.0.2.2 remote-as 64501" -c "neighbor 192.0.2.6 remote-as 64502" -c "address-family ipv4 unicast" -c "network 203.0.113.0/24"'
waitfor edge 'vtysh -c "show bgp summary" | grep "^192.0.2.6" | grep -vq -E "Active|Connect|never"'
sleep 3
root edge 'vtysh -c "show bgp summary"'

block policy
root edge 'vtysh -c "configure terminal" -c "ip prefix-list OURS seq 5 permit 203.0.113.0/24" -c "route-map TO-PROVIDER permit 10" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER deny 5" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.2 route-map TO-PROVIDER out" -c "neighbor 192.0.2.6 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out"'
waitfor edge 'vtysh -c "show ip bgp" | grep -q "64502 64501"'
waitfor ispa 'vtysh -c "show ip bgp" | grep -q "203.0.113.0"'
waitfor ispb 'vtysh -c "show ip bgp" | grep -q "64501 64500"'
root edge 'vtysh -c "show bgp summary"'

block as-path
root edge 'vtysh -c "show ip bgp"'
root edge 'ip route'
on a1 'traceroute -n 203.0.113.10'
on b1 'traceroute -n 203.0.113.10'

block inbound
root ispa 'vtysh -c "show ip bgp 203.0.113.0/24"'
root edge 'vtysh -c "configure terminal" -c "route-map TO-ISPA permit 10" -c "match ip address prefix-list OURS" -c "set as-path prepend 64500 64500" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map TO-ISPA out"'
waitfor ispa 'vtysh -c "show ip bgp" | grep -q "64500 64500 64500"'
sleep 3
root ispa 'vtysh -c "show ip bgp 203.0.113.0/24"'
on a1 'traceroute -n 203.0.113.10'

block leak
root edge 'vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"'
root edge 'vtysh -c "configure terminal" -c "route-map EVERYTHING permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map EVERYTHING out"'
sleep 8
root edge 'vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"'
root ispb 'vtysh -c "show ip bgp 198.51.100.0/25"'
root edge 'vtysh -c "configure terminal" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out" -c "neighbor 192.0.2.2 maximum-prefix 1000" -c "neighbor 192.0.2.6 maximum-prefix 1000"'
sleep 8
root edge 'vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"'
root edge 'vtysh -c "show running-config" | sed -n "/^router bgp/,\$p"'
